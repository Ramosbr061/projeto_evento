import express from "express";
import pool from "../db_mysql.js";

const router = express.Router();

router.get("/", async (_req, res) => {
    const [eventos] = await pool.query("SELECT * FROM eventos");
    res.json(eventos);
});

router.post("/", async (req, res) => {
    const { evento_id, titulo, data_inicio, capacidade } = req.body;

    await pool.query(
        "INSERT INTO eventos (evento_id, titulo, data_inicio, capacidade) VALUES (?, ?, ?, ?)",
        [evento_id, titulo, data_inicio, capacidade]
    );

    res.json({ mensagem: "Evento criado com sucesso!" });
});

export default router;
