import LogApi from "../db_mongo.js";

export default function logger(req, res, next) {
    res.on("finish", () => {
        LogApi.create({
            usuario_id: req.body?.usuario_id || null,
            acao: req.path,
            rota: req.originalUrl,
            metodo: req.method,
            payload: req.body,
            ip: req.ip,
            userAgent: req.get("User-Agent"),
            resultado: res.statusCode,
        });
    });

    next();
}
