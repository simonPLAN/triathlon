import { creerHandler, type ServicesSuppression } from "./handler.ts";

function assert(condition: unknown, message = "Assertion échouée"): asserts condition {
  if (!condition) throw new Error(message);
}
function fixture() {
  const suppressions: string[] = [];
  let motDePasse = "";
  const services: ServicesSuppression = {
    verifierSession: async (token) => token === "valide" ? { id: "utilisateur-session", email: "test@example.org", mfa: false } : null,
    verifierMotDePasse: async (_email, password) => { motDePasse = password; return password === "secret" ? "ok" : "incorrect"; },
    verifierSchema: async () => true,
    supprimer: async (id) => { suppressions.push(id); return true; },
  };
  return { services, suppressions, motDePasse: () => motDePasse };
}
const requete = (body: unknown = { confirmation: true, motDePasse: "secret" }, token = "valide") =>
  new Request("https://example.org/supprimer-compte", {
    method: "POST", headers: { Authorization: "Bearer " + token },
    body: JSON.stringify(body),
  });

Deno.test("suppression authentifiée utilise uniquement l'identité vérifiée", async () => {
  const f = fixture();
  const reponse = await creerHandler(f.services)(requete());
  assert(reponse.status === 200);
  assert((await reponse.json()).supprime === true);
  assert(f.suppressions.join() === "utilisateur-session");
});
Deno.test("session absente ou falsifiée ne supprime personne", async () => {
  const f = fixture();
  for (const token of ["", "faux"]) {
    assert((await creerHandler(f.services)(requete(undefined, token))).status === 401);
  }
  assert(f.suppressions.length === 0);
});
Deno.test("un identifiant de victime dans la requête est refusé", async () => {
  const f = fixture();
  const reponse = await creerHandler(f.services)(requete({ confirmation: true, motDePasse: "secret", id: "victime" }));
  assert(reponse.status === 400 && f.suppressions.length === 0);
});
Deno.test("confirmation et mot de passe sont obligatoires", async () => {
  const f = fixture();
  for (const body of [{}, { confirmation: false, motDePasse: "secret" }, { confirmation: true, motDePasse: "" }, null]) {
    assert((await creerHandler(f.services)(requete(body))).status === 400);
  }
  assert(f.suppressions.length === 0);
});
Deno.test("mot de passe incorrect et MFA ne déclenchent pas la suppression", async () => {
  const f = fixture();
  assert((await creerHandler(f.services)(requete({ confirmation: true, motDePasse: "incorrect" }))).status === 403);
  f.services.verifierSession = async () => ({ id: "id", email: "test@example.org", mfa: true });
  assert((await creerHandler(f.services)(requete())).status === 403);
  assert(f.suppressions.length === 0);
});
Deno.test("protection SQL absente ou suppression échouée : aucun faux succès", async () => {
  const f = fixture();
  f.services.verifierSchema = async () => false;
  assert((await creerHandler(f.services)(requete())).status === 503);
  assert(f.suppressions.length === 0);
  f.services.verifierSchema = async () => true;
  f.services.supprimer = async () => false;
  const reponse = await creerHandler(f.services)(requete());
  assert(reponse.status === 503 && (await reponse.json()).supprime === false);
});
Deno.test("limite Auth et corps trop volumineux sont refusés", async () => {
  const f = fixture();
  f.services.verifierMotDePasse = async () => "limite";
  assert((await creerHandler(f.services)(requete())).status === 429);
  const requeteVolumineuse = new Request("https://example.org", {
    method: "POST", headers: { Authorization: "Bearer valide" }, body: "x".repeat(5000),
  });
  assert((await creerHandler(f.services)(requeteVolumineuse)).status === 413);
  assert(f.suppressions.length === 0);
});
Deno.test("aucune exception technique ni secret dans la réponse", async () => {
  const f = fixture();
  f.services.supprimer = async () => { throw new Error("SECRET_SERVICE_ROLE"); };
  const reponse = await creerHandler(f.services)(requete());
  assert(reponse.status === 503);
  assert(!(await reponse.text()).includes("SECRET"));
});
Deno.test("prévol CORS et GET n'effectuent aucune suppression", async () => {
  const f = fixture();
  const handler = creerHandler(f.services);
  assert((await handler(new Request("https://example.org", { method: "OPTIONS" }))).status === 204);
  assert((await handler(new Request("https://example.org"))).status === 405);
  assert(f.suppressions.length === 0);
});
