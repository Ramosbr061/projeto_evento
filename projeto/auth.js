import express from "express";
import pool from "../db_mysql.js";

const router = express.Router();

router.post("/login", async (req, res) => {
    const { email, senha } = req.body;

    const [rows] = await pool.query("SELECT * FROM usuarios WHERE email = ?", [email]);

    if (rows.length === 0)
        return res.status(400).json({ erro: "Usuário não encontrado" });

    const user = rows[0];

    if (senha !== user.senha_hash)
        return res.status(400).json({ erro: "Senha incorreta" });

    return res.json({
        mensagem: "Login realizado!",
        usuario: user
    });
});

export default router;
