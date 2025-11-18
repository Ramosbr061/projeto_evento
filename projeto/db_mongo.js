import mongoose from "mongoose";

mongoose.connect("mongodb://localhost:27017/logs_db")
    .then(() => console.log("MongoDB conectado!"))
    .catch(err => console.error("Erro ao conectar MongoDB:", err));

const logSchema = new mongoose.Schema({
    usuario_id: String,
    acao: String,
    rota: String,
    metodo: String,
    payload: Object,
    ip: String,
    userAgent: String,
    resultado: String,
    createdAt: { type: Date, default: Date.now }
});

export default mongoose.model("LogApi", logSchema);
