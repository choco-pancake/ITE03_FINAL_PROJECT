<?php

namespace Database\Seeders;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Seed Academic Classes
        $class1 = AcademicClass::create([
            'name' => 'Web Development',
            'section' => 'BSIT 2A',
            'class_code' => 'WD2A-7K92',
            'description' => 'Full stack web development course covering frontend, backend, and API integrations.',
            'student_count' => 30,
        ]);

        $class2 = AcademicClass::create([
            'name' => 'Mobile Application Development',
            'section' => 'BSCS 3B',
            'class_code' => 'MAD3-8M14',
            'description' => 'Cross-platform mobile application development using Flutter and modern frameworks.',
            'student_count' => 28,
        ]);

        $class3 = AcademicClass::create([
            'name' => 'Database Management Systems',
            'section' => 'BSIT 2B',
            'class_code' => 'DBMS-9Q32',
            'description' => 'Relational database schema modeling, normalization, SQL optimization, and NoSQL.',
            'student_count' => 32,
        ]);

        $class4 = AcademicClass::create([
            'name' => 'Information Assurance & Security',
            'section' => 'BSCS 4A',
            'class_code' => 'IAS4-2V88',
            'description' => 'Cybersecurity fundamentals, network defense, vulnerability assessment, and cryptography.',
            'student_count' => 25,
        ]);

        // 2. Seed Grouping Activities (Aivhan's Module)
        GroupingActivity::create([
            'academic_class_id' => $class1->id,
            'class_name' => $class1->display_name,
            'title' => 'Final Capstone Project',
            'description' => 'Design, build, and present a complete web application with dynamic database integration, responsive UI, and secure API endpoints.',
            'grouping_method' => 'hybrid',
            'group_capacity' => 5,
            'number_of_groups' => 6,
            'required_skills' => [
                'Frontend Development',
                'Backend Development',
                'Database Management',
            ],
            'preferred_skills' => [
                'UI/UX Design',
                'Technical Documentation',
            ],
            'min_proficiency_level' => 'Intermediate',
            'min_common_hours' => 5,
            'grouping_deadline' => now()->addDays(20),
            'student_modification_deadline' => now()->addDays(23),
            'status' => 'open',
            'students_count' => 30,
        ]);

        GroupingActivity::create([
            'academic_class_id' => $class2->id,
            'class_name' => $class2->display_name,
            'title' => 'Cross-Platform Mobile App Sprint',
            'description' => 'Develop a cross-platform mobile client with offline caching, push notifications, and clean UI/UX interaction flows.',
            'grouping_method' => 'auto',
            'group_capacity' => 4,
            'number_of_groups' => 7,
            'required_skills' => [
                'Mobile App Development',
                'API Development and Integration',
                'UI/UX Design',
            ],
            'preferred_skills' => [
                'Software Testing and Quality Assurance',
                'Cybersecurity',
            ],
            'min_proficiency_level' => 'Intermediate',
            'min_common_hours' => 4,
            'grouping_deadline' => now()->addDays(7),
            'student_modification_deadline' => now()->addDays(9),
            'status' => 'grouping in progress',
            'students_count' => 28,
        ]);

        GroupingActivity::create([
            'academic_class_id' => $class3->id,
            'class_name' => $class3->display_name,
            'title' => 'Enterprise Schema Modeling & Query Optimization',
            'description' => 'Form balanced teams to develop a normalized schema, migration scripts, and perform indexing and query profiling benchmarks.',
            'grouping_method' => 'manual',
            'group_capacity' => 4,
            'number_of_groups' => 8,
            'required_skills' => [
                'Database Management',
                'System Analysis and Design',
                'Technical Documentation',
            ],
            'preferred_skills' => [
                'Backend Development',
                'Research and Problem Solving',
            ],
            'min_proficiency_level' => 'Beginner',
            'min_common_hours' => 3,
            'grouping_deadline' => now()->subDays(5),
            'student_modification_deadline' => now()->subDays(3),
            'status' => 'completed',
            'students_count' => 32,
        ]);

        GroupingActivity::create([
            'academic_class_id' => $class4->id,
            'class_name' => $class4->display_name,
            'title' => 'Network Vulnerability Audit & Defense Plan',
            'description' => 'Execute simulated penetration tests, packet inspection, and author a comprehensive mitigation roadmap for enterprise infrastructure.',
            'grouping_method' => 'auto',
            'group_capacity' => 5,
            'number_of_groups' => 5,
            'required_skills' => [
                'Cybersecurity',
                'Networking',
                'Research and Problem Solving',
            ],
            'preferred_skills' => [
                'Technical Documentation',
            ],
            'min_proficiency_level' => 'Advanced',
            'min_common_hours' => 6,
            'grouping_deadline' => now()->addDays(14),
            'student_modification_deadline' => now()->addDays(16),
            'status' => 'draft',
            'students_count' => 25,
        ]);

        // 3. Seed Sample Profiles
        Profile::create([
            'name' => 'Alex Santos',
            'email' => 'alex.santos@student.edu',
            'skills' => ['Frontend Development', 'UI/UX Design', 'JavaScript'],
            'interests' => ['Web Development', 'UI/UX and Creative Design'],
            'preferred_role' => 'Frontend Developer',
            'availability' => 'Mon, Tue, Thu afternoon (3-6 PM)',
        ]);

        Profile::create([
            'name' => 'Bea Cruz',
            'email' => 'bea.cruz@student.edu',
            'skills' => ['Backend Development', 'Database Management', 'PHP', 'Laravel'],
            'interests' => ['Web Development', 'Data and Analytics'],
            'preferred_role' => 'Backend Developer',
            'availability' => 'Tue, Wed, Fri (2-5 PM)',
        ]);
    }
}
