const API = "http://localhost:3000/api";

async function login() {
    const email = document.getElementById("email").value;
    const senha = document.getElementById("senha").value;

    const res = await fetch(`${API}/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, senha })
    });

    const json = await res.json();
    alert(JSON.stringify(json));
}

async function carregarEventos() {
    const res = await fetch(`${API}/eventos`);
    const eventos = await res.json();

    const lista = document.getElementById("lista");
    lista.innerHTML = "";

    eventos.forEach(e => {
        lista.innerHTML += `<li>${e.titulo} — ${e.data_inicio}</li>`;
    });
}
