// Logique injectable pour tester sans clé privilégiée ni serveur réel.
export interface CompteVerifie {
  id: string;
  email: string;
  mfa: boolean;
}
export interface ServicesSuppression {
  verifierSession(token: string): Promise<CompteVerifie | null>;
  verifierMotDePasse(email: string, password: string, id: string): Promise<"ok" | "incorrect" | "limite">;
  verifierSchema(): Promise<boolean>;
  supprimer(id: string): Promise<boolean>;
}
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
  "Cache-Control": "no-store",
};
const reponse = (status: number, code: string, supprime = false) =>
  Response.json({ code, supprime }, { status, headers: cors });

export function creerHandler(services: ServicesSuppression) {
  return async (request: Request): Promise<Response> => {
    if (request.method === "OPTIONS") return new Response(null, { status: 204, headers: cors });
    if (request.method !== "POST") return reponse(405, "methode_interdite");
    const token = /^Bearer (\S+)$/i.exec(request.headers.get("Authorization") ?? "")?.[1];
    if (!token) return reponse(401, "session_invalide");
    try {
      // Lire au plus 4 Kio, même si Content-Length est absent ou falsifié.
      const reader = request.body?.getReader();
      if (!reader) return reponse(400, "demande_invalide");
      const morceaux: Uint8Array[] = [];
      let taille = 0;
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;
        taille += value.byteLength;
        if (taille > 4096) { await reader.cancel(); return reponse(413, "demande_invalide"); }
        morceaux.push(value);
      }
      const texte = new Uint8Array(taille);
      let offset = 0;
      for (const morceau of morceaux) { texte.set(morceau, offset); offset += morceau.length; }
      let body;
      try { body = JSON.parse(new TextDecoder().decode(texte)); }
      catch { return reponse(400, "demande_invalide"); }
      if (!body || body.confirmation !== true || typeof body.motDePasse !== "string" ||
          body.motDePasse.length === 0 || body.motDePasse.length > 1024 ||
          Object.keys(body).some((key) => !["confirmation", "motDePasse"].includes(key))) {
        return reponse(400, "demande_invalide");
      }
      // L'identifiant vient exclusivement de getUser(token), jamais de la requête.
      const compte = await services.verifierSession(token);
      if (!compte) return reponse(401, "session_invalide");
      // Ne pas contourner un second facteur avec le seul mot de passe.
      if (compte.mfa) return reponse(403, "mfa_requise");
      const verification = await services.verifierMotDePasse(compte.email, body.motDePasse, compte.id);
      if (verification === "limite") return reponse(429, "trop_de_demandes");
      if (verification !== "ok") return reponse(403, "mot_de_passe_incorrect");
      if (!await services.verifierSchema()) return reponse(503, "suppression_indisponible");
      if (!await services.supprimer(compte.id)) return reponse(503, "suppression_indisponible");
      return reponse(200, "compte_supprime", true);
    } catch {
      // Ne jamais renvoyer ni journaliser mot de passe, token, e-mail ou erreur SQL.
      return reponse(503, "suppression_indisponible");
    }
  };
}
