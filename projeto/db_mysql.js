import mysql from "mysql2/promise";

const pool = mysql.createPool({
    host: "localhost",
    user: "app_user",
    password: "senha_forte",
    database: "eventos_db"
});

export default pool;
