-- 1. Criação de esquema (não usar root para aplicação)
CREATE DATABASE IF NOT EXISTS eventos_db;
USE eventos_db;

-- 2. Tabela grupos_usuarios
CREATE TABLE grupos_usuarios (
  grupo_id VARCHAR(50) PRIMARY KEY,
  nome VARCHAR(100) NOT NULL,
  descricao TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Tabela usuarios
CREATE TABLE usuarios (
  usuario_id VARCHAR(50) PRIMARY KEY,
  nome VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,
  grupo_id VARCHAR(50) NOT NULL,
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  ultimo_login TIMESTAMP NULL,
  FOREIGN KEY (grupo_id) REFERENCES grupos_usuarios(grupo_id)
);

-- 4. Tabela eventos
CREATE TABLE eventos (
  evento_id VARCHAR(50) PRIMARY KEY,
  titulo VARCHAR(200) NOT NULL,
  descricao TEXT,
  data_inicio DATETIME NOT NULL,
  data_fim DATETIME,
  local VARCHAR(200),
  capacidade INT,
  criado_por VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (criado_por) REFERENCES usuarios(usuario_id)
);

-- 5. Tabela inscricoes
CREATE TABLE inscricoes (
  inscricao_id VARCHAR(50) PRIMARY KEY,
  evento_id VARCHAR(50) NOT NULL,
  usuario_id VARCHAR(50) NOT NULL,
  status ENUM('PENDENTE','CONFIRMADA','CANCELADA') NOT NULL DEFAULT 'PENDENTE',
  criado_em TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (evento_id, usuario_id),
  FOREIGN KEY (evento_id) REFERENCES eventos(evento_id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(usuario_id)
);

-- 6. Tabela pagamentos
CREATE TABLE pagamentos (
  pagamento_id VARCHAR(50) PRIMARY KEY,
  inscricao_id VARCHAR(50) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  metodo VARCHAR(50),
  status ENUM('PAGO','PENDENTE','ESTORNADO') DEFAULT 'PENDENTE',
  pago_em TIMESTAMP NULL,
  FOREIGN KEY (inscricao_id) REFERENCES inscricoes(inscricao_id)
);

CREATE INDEX idx_evento_data ON eventos(data_inicio);
CREATE INDEX idx_usuario_email ON usuarios(email);
CREATE INDEX idx_inscricao_evento ON inscricoes(evento_id);
-- Função utilitária para gerar ID com timestamp + random
DROP FUNCTION IF EXISTS gera_id;
DELIMITER $$
CREATE FUNCTION gera_id(prefix VARCHAR(10)) RETURNS VARCHAR(100) DETERMINISTIC
BEGIN
  DECLARE newid VARCHAR(100);
  SET newid = CONCAT(prefix,'-',DATE_FORMAT(NOW(),'%Y%m%d%H%i%s'),'-',LPAD(FLOOR(RAND()*9999),4,'0'));
  RETURN newid;
END$$
DELIMITER ;
-- Inserção exemplo usando a função
INSERT INTO grupos_usuarios (grupo_id,nome,descricao) VALUES (gera_id('GRP'),'administradores','Grupo admin');
INSERT INTO usuarios (usuario_id,nome,email,senha_hash,grupo_id) 
VALUES (gera_id('USR'),'Guilherme','guilherme@example.com','$hash','GRP-20251117123000-1234');
-- Procedure: Registrar inscrição (valida disponibilidade)
DROP PROCEDURE IF EXISTS sp_registrar_inscricao;
DELIMITER $$
CREATE PROCEDURE sp_registrar_inscricao(
  IN p_evento_id VARCHAR(50),
  IN p_usuario_id VARCHAR(50),
  OUT p_inscricao_id VARCHAR(50),
  OUT p_msg VARCHAR(255)
)
BEGIN
  DECLARE vagas INT;
  DECLARE total INT;
  SELECT capacidade INTO vagas FROM eventos WHERE evento_id = p_evento_id;
  SELECT COUNT(*) INTO total FROM inscricoes WHERE evento_id = p_evento_id AND status='CONFIRMADA';
  IF vagas IS NULL THEN
    SET p_msg = 'Evento não encontrado';
    SET p_inscricao_id = NULL;
  ELSEIF total >= vagas THEN
    SET p_msg = 'Evento lotado';
    SET p_inscricao_id = NULL;
  ELSE
    SET p_inscricao_id = gera_id('INS');
    INSERT INTO inscricoes(inscricao_id,event p_usuario_id,status) VALUES (p_inscricao_id,p_evento_id,p_usuario_id,'PENDENTE');
    SET p_msg = 'Inscrição registrada (PENDENTE)';
  END IF;
END$$
DELIMITER ;

-- Function: Conta inscrições confirmadas de um evento
DROP FUNCTION IF EXISTS fn_qtd_confirmadas;
DELIMITER $$
CREATE FUNCTION fn_qtd_confirmadas(p_evento_id VARCHAR(50)) RETURNS INT DETERMINISTIC
BEGIN
  DECLARE cnt INT;
  SELECT COUNT(*) INTO cnt FROM inscricoes WHERE evento_id = p_evento_id AND status='CONFIRMADA';
  RETURN cnt;
END$$
DELIMITER ;
-- View 1: Relatório simples de eventos com inscricoes confirmadas
CREATE VIEW vw_eventos_participacao AS
SELECT e.evento_id, e.titulo, e.data_inicio, e.capacidade, 
       (SELECT COUNT(*) FROM inscricoes i WHERE i.evento_id = e.evento_id AND i.status='CONFIRMADA') AS qtd_confirmadas
FROM eventos e;

-- View 2: Usuários com seus grupos
CREATE VIEW vw_usuarios_grupos AS
SELECT u.usuario_id, u.nome, u.email, g.nome AS grupo_nome
FROM usuarios u JOIN grupos_usuarios g ON u.grupo_id = g.grupo_id;
-- Trigger 1: Ao confirmar inscrição, criar pagamento pendente automaticamente
DROP TRIGGER IF EXISTS trg_after_inscricao_update;
DELIMITER $$
CREATE TRIGGER trg_after_inscricao_update
AFTER UPDATE ON inscricoes
FOR EACH ROW
BEGIN
  IF NEW.status = 'CONFIRMADA' AND (OLD.status <> 'CONFIRMADA') THEN
    INSERT INTO pagamentos(pagamento_id,inscricao_id,valor,status) 
    VALUES (gera_id('PAY'), NEW.inscricao_id, 0.00, 'PENDENTE');
  END IF;
END$$
DELIMITER ;

-- Trigger 2: Log mínimo de auditoria (exemplo em tabela relacional ou push para NoSQL)
-- Aqui vamos gravar um registro simples de auditoria em tabela relacional.
CREATE TABLE IF NOT EXISTS auditoria (
  aud_id VARCHAR(60) PRIMARY KEY,
  tabela_nome VARCHAR(100),
  operacao ENUM('INSERT','UPDATE','DELETE'),
  registro_id VARCHAR(100),
  usuario_responsavel VARCHAR(50),
  momento TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS trg_after_usuario_insert;
DELIMITER $$
CREATE TRIGGER trg_after_usuario_insert
AFTER INSERT ON usuarios
FOR EACH ROW
BEGIN
  INSERT INTO auditoria(aud_id,tabela_nome,operacao,registro_id,usuario_responsavel)
  VALUES (gera_id('AUD'),'usuarios','INSERT',NEW.usuario_id,NEW.usuario_id);
END$$
DELIMITER ;
-- Criar usuário da aplicação (ex.: app_user) sem root privileges
CREATE USER 'app_user'@'%' IDENTIFIED BY 'senha_forte';
GRANT SELECT, INSERT, UPDATE, DELETE ON eventos_db.* TO 'app_user'@'%';
-- Administrador do BD (ops) com mais privilégios
CREATE USER 'dba'@'localhost' IDENTIFIED BY 'senha_dba';
GRANT ALL PRIVILEGES ON eventos_db.* TO 'dba'@'localhost';
FLUSH PRIVILEGES;

 