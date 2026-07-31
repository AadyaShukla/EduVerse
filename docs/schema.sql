-- Database schema for EduVerse (PostgreSQL via Supabase)

CREATE TABLE students (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    grade INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    parent_link_required BOOLEAN NOT NULL DEFAULT false,
    parent_id UUID -- nullable FK
);

CREATE TABLE guardians (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    email TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);

ALTER TABLE students
ADD CONSTRAINT fk_students_guardian
FOREIGN KEY (parent_id) REFERENCES guardians(id);

CREATE TABLE student_guardian_links (
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    guardian_id UUID NOT NULL REFERENCES guardians(id) ON DELETE CASCADE,
    linked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now()),
    status TEXT NOT NULL, -- e.g., 'pending', 'active'
    PRIMARY KEY (student_id, guardian_id)
);

CREATE TABLE lecture_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    topic TEXT NOT NULL,
    current_segment INTEGER DEFAULT 0,
    paused_at TIMESTAMP WITH TIME ZONE,
    completed BOOLEAN NOT NULL DEFAULT false
);

CREATE TABLE doubts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id UUID NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    language TEXT NOT NULL,
    answer_summary TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc', now())
);
