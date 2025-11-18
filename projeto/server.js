import express from "express";
import cors from "cors";

import logger from "./middlewares/logger.js";
import "./db_mongo.js";

import authRoutes from "./routes/auth.js";
import eventosRoutes from "./routes/eventos.js";

const app = express();
app.use(cors());
app.use(express.json());
app.use(logger);

app.use("/api/auth", authRoutes);
app.use("/api/eventos", eventosRoutes);

app.listen(3000, () => {
    console.log("Servidor rodando: http://localhost:3000");
});
