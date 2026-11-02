import { createClient } from "npm:@supabase/supabase-js@2.118.0";
import { creerHandler } from "./handler.ts";

const url = Deno.env.get("SUPABASE_URL")!;
const clePublique = Deno.env.get("SUPABASE_ANON_KEY")!;
const cleServeur = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const options = { auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false } };
const admin = createClient(url, cleServeur, options);

Deno.serve(creerHandler({
  async verifierSession(token) {
    const { data, error } = await admin.auth.getUser(token);
    const user = data.user;
    if (error || !user || !user.email || !user.email_confirmed_at || user.is_anonymous) return null;
    return {
      id: user.id, email: user.email,
      mfa: (user.factors ?? []).some((factor) => factor.status === "verified"),
    };
  },
  async verifierMotDePasse(email, password, id) {
    // Client isolé : ne jamais remplacer la session de l'appelant ou de l'admin.
    const verification = createClient(url, clePublique, options);
    const { data, error } = await verification.auth.signInWithPassword({ email, password });
    if (error) return error.status === 429 ? "limite" : "incorrect";
    const valide = data.user?.id === id && !!data.session;
    // Révoquer uniquement cette session de vérification.
    try { await verification.auth.signOut({ scope: "local" }); }
    catch { /* Aucun stockage persistant dans ce client. */ }
    return valide ? "ok" : "incorrect";
  },
  async verifierSchema() {
    const { error } = await admin.rpc("verifier_schema_suppression_compte");
    return !error;
  },
  async supprimer(id) {
    // Hard delete, trigger transactionnel avant suppression Auth.
    const { error } = await admin.auth.admin.deleteUser(id, false);
    return !error;
  },
}));
