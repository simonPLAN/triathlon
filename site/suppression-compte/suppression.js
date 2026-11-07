"use strict";
const configuration = window.configurationSuppression;
const formulaire = document.querySelector("#suppression");
const message = document.querySelector("#message");
const bouton = formulaire.querySelector("button");
let enCours = false;
if (configuration.contact) {
  const support = document.querySelector("#support");
  const lien = document.createElement("a");
  lien.href = "mailto:" + configuration.contact;
  lien.textContent = configuration.contact;
  support.append("Besoin d’aide ou compte protégé par double authentification ? Contacte ", lien, ".");
  support.hidden = false;
}
if (Number.isInteger(configuration.retentionSauvegardesJours)) {
  document.querySelector("#sauvegardes").textContent =
    "Durée maximale des sauvegardes : " + configuration.retentionSauvegardesJours + " jours.";
}
formulaire.addEventListener("submit", async (event) => {
  event.preventDefault();
  if (enCours || !formulaire.reportValidity()) return;
  enCours = true;
  bouton.disabled = true;
  message.textContent = "Vérification et suppression en cours…";
  let accessToken;
  let motDePasse = document.querySelector("#password").value;
  const email = document.querySelector("#email").value.trim();
  try {
    const auth = await fetch(configuration.urlSupabase + "/auth/v1/token?grant_type=password", {
      method: "POST", cache: "no-store", credentials: "omit",
      headers: { "apikey": configuration.clePublique, "Content-Type": "application/json" },
      body: JSON.stringify({ email, password: motDePasse }),
    });
    const session = await auth.json();
    if (!auth.ok || !session.access_token) {
      throw new Error(auth.status === 429 ? "Trop de tentatives. Patiente puis réessaie." :
        "Connexion impossible. Vérifie tes identifiants et la confirmation de ton e-mail.");
    }
    accessToken = session.access_token;
    const resultat = await fetch(configuration.urlSupabase + "/functions/v1/supprimer-compte", {
      method: "POST", cache: "no-store", credentials: "omit",
      headers: {
        "apikey": configuration.clePublique, "Authorization": "Bearer " + accessToken,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ motDePasse, confirmation: true }),
    });
    const reponse = await resultat.json();
    if (!resultat.ok || reponse.supprime !== true) {
      const erreurs = {
        mfa_requise: "Ton compte utilise la double authentification. Contacte le support pour vérifier ton identité.",
        mot_de_passe_incorrect: "Mot de passe incorrect. Réessaie.",
        session_invalide: "La session a expiré. Réessaie.",
        trop_de_demandes: "Trop de tentatives. Patiente puis réessaie.",
      };
      throw new Error(erreurs[reponse.code] || "Suppression indisponible. Réessaie plus tard ou contacte le support.");
    }
    formulaire.hidden = true;
    formulaire.reset();
    message.textContent = "Ton compte et tes données personnelles ont été supprimés.";
  } catch (erreur) {
    message.textContent = erreur instanceof TypeError
      ? "Connexion interrompue : la suppression n’est pas confirmée. Réessaie ou contacte le support."
      : erreur.message;
  } finally {
    // Révoquer la session temporaire même après une erreur. Aucun stockage local.
    if (accessToken) {
      try {
        await fetch(configuration.urlSupabase + "/auth/v1/logout?scope=local", {
          method: "POST", credentials: "omit",
          headers: { "apikey": configuration.clePublique, "Authorization": "Bearer " + accessToken },
        });
      } catch { /* Un compte supprimé ne possède plus de session renouvelable. */ }
    }
    accessToken = undefined;
    motDePasse = "";
    document.querySelector("#password").value = "";
    enCours = false;
    bouton.disabled = false;
  }
});
