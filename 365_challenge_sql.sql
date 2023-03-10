USE 365_database;

# Construindo três tabelas com informações sobre os cursos, os tipos de estudantes, e a terceira sobre os estudantes e seus respectivos cursos.

# Criando a primeira tabela com informações sobre os cursos mais populares.

DROP TABLE course_info;
CREATE TABLE IF NOT EXISTS course_info 
(
	course_id int not null,
    course_name VARCHAR(225) NOT NULL,
    total_minutes_watched DOUBLE,
    average_minutes_watched DOUBLE,
    number_of_rating INT,
    average_course_rating DOUBLE
);

# Inserir os dados sobre os cursos. As colunas nessa fonte de dados são diretas a que se propõe.

INSERT INTO course_info
SELECT 
    ci.course_id,
    ci.course_title,
    SUM(sl.minutes_watched) AS minutes_watched,
    AVG(sl.minutes_watched) AS average_minutes_watched,
    cr.number_of_rating,
    cr.average_rating
FROM
    365_course_info ci
		JOIN
    365_student_learning sl USING (course_id)
		JOIN
    (SELECT 
        course_id,
            COUNT(course_rating) AS number_of_rating,
            AVG(course_rating) AS average_rating
    FROM
        365_course_ratings
    GROUP BY course_id) cr USING (course_id)
GROUP BY ci.course_id;


# Construindo a segunda fonte de dados. Que contem informações sobre os tipos de estudantes. 

DROP TABLE user_type;
CREATE TABLE IF NOT EXISTS user_type
 (
    user_id INT NOT NULL PRIMARY KEY,
    date_of_registration DATE,
    country VARCHAR(225),
    onboarded ENUM('Yes', 'No'),
    paid ENUM('Yes', 'No'),
    user_type INT,
    course_id INT
);

# Inserindo os dados na segunda tabela. A coluna onboard categoriza se o usuário da plataforma fez ao menos um quiz, ou um exame, ou assistiu à alguma aula. Na coluna paid considera-se usuário 'No' aquele que nunca fez uma compra na plataforma, ao contrário, os pagantes realizaram pelo menos um tipo de assinatura. As demais colunas são diretas ao que se referem.

INSERT INTO user_type
SELECT 
    si.student_id,
    si.date_registered,
    si.student_country,
    CASE
        WHEN se.engagement_quizzes = 1 THEN 'Yes'
        WHEN se.engagement_exams = 1 THEN 'Yes'
        WHEN se.engagement_lessons = 1 THEN 'Yes'
        ELSE 'No'
    END AS onboard,
    CASE
        WHEN sp.purchase_type = 'Annual' THEN 'Yes'
        WHEN sp.purchase_type = 'Monthly' THEN 'Yes'
        WHEN sp.purchase_type = 'Quarterly' THEN 'Yes'
        ELSE 'No'
    END AS paid,
    CASE
        WHEN sp.purchase_type = 'Monthly' THEN 0
        WHEN sp.purchase_type = 'Quarterly' THEN 1
        WHEN sp.purchase_type = 'Annual' THEN 2
        ELSE NULL
    END AS user_type,
    sl.course_id
FROM
    365_student_info si
        LEFT JOIN
    365_student_engagement se ON si.student_id = se.student_id
        LEFT JOIN
    365_student_purchases sp ON se.student_id = sp.student_id
		LEFT JOIN
    365_student_learning sl ON si.student_id = sl.student_id
GROUP BY si.student_id;

# Criando a terceira tabela, em que temos informações sobre os estudantes e os cursos que fizeram ou iniciaram.

DROP TABLE IF EXISTS user_course;
CREATE TABLE IF NOT EXISTS user_course (
    user_id INT NOT NULL,
    date_watched DATE,
    course_id INT,
    minutes_watched FLOAT,
    paid ENUM('Yes', 'No'),
    user_type INT,
    date_of_registration DATE,
    country VARCHAR(225),
    onboarded ENUM('Yes', 'No')
);

# Inserindo os dados. Aqui processa os dados sobre os usuários e os cursos que eles concluíram ou pelo menos começaram. 

INSERT INTO user_course
SELECT 
    sl.student_id,
    sl.date_watched,
    sl.course_id,
    SUM(sl.minutes_watched),
    ut.paid,
    ut.user_type,
    ut.date_of_registration,
    ut.country,
    ut.onboarded
FROM
    365_student_learning sl
        JOIN
    user_type ut ON sl.student_id = ut.user_id
GROUP BY student_id , course_id;

# A visualização destes dados foi realizada com software Tableau com a criação de uma dashboard.




