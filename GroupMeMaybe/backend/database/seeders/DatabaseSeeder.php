<?php

namespace Database\Seeders;

use App\Models\AcademicClass;
use App\Models\GroupingActivity;
use App\Models\Profile;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Schema;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // Clear previous records for clean seeding
        Schema::disableForeignKeyConstraints();
        GroupingActivity::truncate();
        AcademicClass::truncate();
        Profile::truncate();
        Schema::enableForeignKeyConstraints();

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

        // 2. Seed 30 Realistic Student Profiles
        $profilesData = [
            [
                'name' => 'Alex Santos',
                'email' => 'alex.santos@student.edu',
                'skills' => ['Frontend Development', 'UI/UX Design', 'JavaScript'],
                'interests' => ['Web Development', 'UI/UX and Creative Design'],
                'preferred_role' => 'Frontend Developer',
                'availability' => 'Mon, Tue, Thu afternoon (3-6 PM)',
            ],
            [
                'name' => 'Bea Cruz',
                'email' => 'bea.cruz@student.edu',
                'skills' => ['Backend Development', 'Database Management', 'PHP', 'Laravel'],
                'interests' => ['Web Development', 'Data and Analytics'],
                'preferred_role' => 'Backend Developer',
                'availability' => 'Tue, Wed, Fri (2-5 PM)',
            ],
            [
                'name' => 'Carl Reyes',
                'email' => 'carl.reyes@student.edu',
                'skills' => ['UI/UX Design', 'Frontend Development', 'Figma'],
                'interests' => ['Product Design', 'Web Interfaces'],
                'preferred_role' => 'UI/UX Designer',
                'availability' => 'Mon, Wed, Fri (1-4 PM)',
            ],
            [
                'name' => 'Dani Garcia',
                'email' => 'dani.garcia@student.edu',
                'skills' => ['Software Testing and Quality Assurance', 'Technical Documentation'],
                'interests' => ['Quality Assurance', 'Technical Writing'],
                'preferred_role' => 'QA Specialist',
                'availability' => 'Weekdays after 2 PM',
            ],
            [
                'name' => 'Ethan Lim',
                'email' => 'ethan.lim@student.edu',
                'skills' => ['Database Management', 'Backend Development', 'SQL'],
                'interests' => ['Database Systems', 'Cloud Data'],
                'preferred_role' => 'Database Administrator',
                'availability' => 'Tue, Thu, Sat mornings (9-12 AM)',
            ],
            [
                'name' => 'Gabe Tan',
                'email' => 'gabe.tan@student.edu',
                'skills' => ['Backend Development', 'API Development and Integration', 'Node.js'],
                'interests' => ['Microservices', 'REST APIs'],
                'preferred_role' => 'Backend Developer',
                'availability' => 'Mon, Wed, Thu (3-7 PM)',
            ],
            [
                'name' => 'Hana Cruz',
                'email' => 'hana.cruz@student.edu',
                'skills' => ['System Analysis and Design', 'Technical Documentation', 'UI/UX Design'],
                'interests' => ['System Architecture', 'Design Thinking'],
                'preferred_role' => 'System Analyst',
                'availability' => 'Weekdays 10 AM - 3 PM',
            ],
            [
                'name' => 'Liam Torres',
                'email' => 'liam.torres@student.edu',
                'skills' => ['Mobile App Development', 'Flutter', 'Dart'],
                'interests' => ['Cross-Platform Apps', 'Mobile Engineering'],
                'preferred_role' => 'Mobile App Developer',
                'availability' => 'Mon, Tue, Thu (1-5 PM)',
            ],
            [
                'name' => 'Chloe Mendoza',
                'email' => 'chloe.mendoza@student.edu',
                'skills' => ['UI/UX Design', 'Mobile App Development', 'Figma'],
                'interests' => ['Mobile UI', 'Human Computer Interaction'],
                'preferred_role' => 'UI/UX Designer',
                'availability' => 'Tue, Wed, Fri (2-6 PM)',
            ],
            [
                'name' => 'Marcus Vance',
                'email' => 'marcus.vance@student.edu',
                'skills' => ['API Development and Integration', 'Backend Development', 'Kotlin'],
                'interests' => ['Cloud Integrations', 'Mobile Backends'],
                'preferred_role' => 'API Developer',
                'availability' => 'Weekdays after 4 PM',
            ],
            [
                'name' => 'Jessa Fernandez',
                'email' => 'jessa.fernandez@student.edu',
                'skills' => ['Software Testing and Quality Assurance', 'Technical Documentation'],
                'interests' => ['Automated Testing', 'Agile Documentation'],
                'preferred_role' => 'QA Engineer',
                'availability' => 'Mon, Wed, Fri (9-12 AM)',
            ],
            [
                'name' => 'David Reyes',
                'email' => 'david.reyes@student.edu',
                'skills' => ['Database Management', 'System Analysis and Design', 'MySQL'],
                'interests' => ['Enterprise Databases', 'Query Optimization'],
                'preferred_role' => 'Database Analyst',
                'availability' => 'Mon, Thu, Fri (1-4 PM)',
            ],
            [
                'name' => 'Rachel Kim',
                'email' => 'rachel.kim@student.edu',
                'skills' => ['Technical Documentation', 'Research and Problem Solving'],
                'interests' => ['Technical Authoring', 'Process Audits'],
                'preferred_role' => 'Technical Writer',
                'availability' => 'Weekdays 2-6 PM',
            ],
            [
                'name' => 'Victor Gomez',
                'email' => 'victor.gomez@student.edu',
                'skills' => ['Cybersecurity', 'Networking', 'Linux'],
                'interests' => ['Threat Defense', 'Penetration Testing'],
                'preferred_role' => 'Security Analyst',
                'availability' => 'Mon, Wed, Fri afternoons (1-5 PM)',
            ],
            [
                'name' => 'Sarah Jenkins',
                'email' => 'sarah.jenkins@student.edu',
                'skills' => ['Networking', 'Cybersecurity', 'Research and Problem Solving'],
                'interests' => ['Network Infrastructure', 'Firewall Auditing'],
                'preferred_role' => 'Network Engineer',
                'availability' => 'Tue, Thu, Sat (10 AM - 2 PM)',
            ],
            [
                'name' => 'Kevin O\'Connor',
                'email' => 'kevin.oconnor@student.edu',
                'skills' => ['Frontend Development', 'Backend Development', 'React'],
                'interests' => ['Fullstack Apps', 'Progressive Web Apps'],
                'preferred_role' => 'Fullstack Developer',
                'availability' => 'Weekdays after 3 PM',
            ],
            [
                'name' => 'Maria Santos',
                'email' => 'maria.santos@student.edu',
                'skills' => ['UI/UX Design', 'Frontend Development'],
                'interests' => ['Design Systems', 'Interactive Design'],
                'preferred_role' => 'UI/UX Designer',
                'availability' => 'Mon, Tue, Thu (10 AM - 1 PM)',
            ],
            [
                'name' => 'Joshua Diaz',
                'email' => 'joshua.diaz@student.edu',
                'skills' => ['Networking', 'Backend Development', 'System Analysis and Design'],
                'interests' => ['DevOps', 'Distributed Systems'],
                'preferred_role' => 'DevOps Engineer',
                'availability' => 'Tue, Wed, Fri (3-6 PM)',
            ],
            [
                'name' => 'Alyssa Valenzuela',
                'email' => 'alyssa.valenzuela@student.edu',
                'skills' => ['Software Testing and Quality Assurance', 'Research and Problem Solving'],
                'interests' => ['Test Automation', 'Bug Bounties'],
                'preferred_role' => 'QA Specialist',
                'availability' => 'Weekdays 1-5 PM',
            ],
            [
                'name' => 'Paolo Ramos',
                'email' => 'paolo.ramos@student.edu',
                'skills' => ['Mobile App Development', 'Flutter', 'UI/UX Design'],
                'interests' => ['Native Apps', 'Mobile Prototyping'],
                'preferred_role' => 'Mobile Developer',
                'availability' => 'Mon, Wed, Fri (2-6 PM)',
            ],
            [
                'name' => 'Nicole Tan',
                'email' => 'nicole.tan@student.edu',
                'skills' => ['Research and Problem Solving', 'Technical Documentation'],
                'interests' => ['Algorithms', 'Research Studies'],
                'preferred_role' => 'Research Analyst',
                'availability' => 'Tue, Thu (1-5 PM)',
            ],
            [
                'name' => 'Christian Perez',
                'email' => 'christian.perez@student.edu',
                'skills' => ['Cybersecurity', 'Research and Problem Solving'],
                'interests' => ['Cryptography', 'Network Forensics'],
                'preferred_role' => 'Security Specialist',
                'availability' => 'Weekdays after 4 PM',
            ],
            [
                'name' => 'Andrea Castro',
                'email' => 'andrea.castro@student.edu',
                'skills' => ['Database Management', 'Backend Development'],
                'interests' => ['Data Warehouses', 'SQL Tuning'],
                'preferred_role' => 'Database Engineer',
                'availability' => 'Mon, Tue, Thu mornings',
            ],
            [
                'name' => 'Mark Bautista',
                'email' => 'mark.bautista@student.edu',
                'skills' => ['Frontend Development', 'UI/UX Design'],
                'interests' => ['Responsive Design', 'Accessibility'],
                'preferred_role' => 'Frontend Developer',
                'availability' => 'Wed, Fri, Sat (1-5 PM)',
            ],
            [
                'name' => 'Patricia Soriano',
                'email' => 'patricia.soriano@student.edu',
                'skills' => ['Backend Development', 'API Development and Integration'],
                'interests' => ['Cloud Computing', 'API Gateways'],
                'preferred_role' => 'Backend Developer',
                'availability' => 'Weekdays 2-5 PM',
            ],
            [
                'name' => 'Miguel Villanueva',
                'email' => 'miguel.villanueva@student.edu',
                'skills' => ['System Analysis and Design', 'Networking'],
                'interests' => ['Enterprise Systems', 'Infrastructure'],
                'preferred_role' => 'System Architect',
                'availability' => 'Mon, Thu (2-6 PM)',
            ],
            [
                'name' => 'Stephanie Dizon',
                'email' => 'stephanie.dizon@student.edu',
                'skills' => ['Technical Documentation', 'Software Testing and Quality Assurance'],
                'interests' => ['Release Notes', 'User Guides'],
                'preferred_role' => 'Technical Writer',
                'availability' => 'Tue, Wed, Fri (10 AM - 2 PM)',
            ],
            [
                'name' => 'Ryan Navarro',
                'email' => 'ryan.navarro@student.edu',
                'skills' => ['Mobile App Development', 'Frontend Development'],
                'interests' => ['Mobile Hybrid Apps', 'Modern Frameworks'],
                'preferred_role' => 'Mobile Developer',
                'availability' => 'Weekdays after 3 PM',
            ],
            [
                'name' => 'Angela Mercado',
                'email' => 'angela.mercado@student.edu',
                'skills' => ['Cybersecurity', 'Networking'],
                'interests' => ['Security Operations', 'Zero Trust'],
                'preferred_role' => 'Security Engineer',
                'availability' => 'Mon, Wed, Fri (1-4 PM)',
            ],
            [
                'name' => 'Dennis Aquino',
                'email' => 'dennis.aquino@student.edu',
                'skills' => ['Software Testing and Quality Assurance', 'System Analysis and Design'],
                'interests' => ['Quality Engineering', 'Load Testing'],
                'preferred_role' => 'QA Specialist',
                'availability' => 'Weekdays 9 AM - 1 PM',
            ],
        ];

        foreach ($profilesData as $data) {
            Profile::create($data);
        }

        // 3. Seed Grouping Activities (Aivhan's Module)

        // Activity 1: Hybrid mode with a partially formed student team (Alex's team)
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
            'formed_teams' => [
                [
                    'name' => 'Team Alpha Web',
                    'is_auto_assigned' => false,
                    'leader_email' => 'alex.santos@student.edu',
                    'members' => [
                        [
                            'name' => 'Alex Santos (You)',
                            'email' => 'alex.santos@student.edu',
                            'role' => 'Team Leader & Frontend Dev',
                            'block' => 'BSIT 2A',
                            'avatar' => 'A',
                            'is_leader' => true,
                        ],
                        [
                            'name' => 'Carl Reyes',
                            'email' => 'carl.reyes@student.edu',
                            'role' => 'UI/UX Designer',
                            'block' => 'BSIT 2A',
                            'avatar' => 'C',
                            'is_leader' => false,
                        ],
                        [
                            'name' => 'Dani Garcia',
                            'email' => 'dani.garcia@student.edu',
                            'role' => 'QA & Documentation',
                            'block' => 'BSIT 2A',
                            'avatar' => 'D',
                            'is_leader' => false,
                        ],
                    ],
                ],
            ],
        ]);

        // Activity 2: Auto mode, grouping in progress (not completed yet, no formed teams yet)
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
            'formed_teams' => null,
        ]);

        // Activity 3: Completed activity with finalized teams
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
            'formed_teams' => [
                [
                    'name' => 'Query Masters',
                    'is_auto_assigned' => false,
                    'leader_email' => 'ethan.lim@student.edu',
                    'members' => [
                        [
                            'name' => 'Ethan Lim',
                            'email' => 'ethan.lim@student.edu',
                            'role' => 'Team Leader & SQL Engineer',
                            'block' => 'BSIT 2B',
                            'avatar' => 'E',
                            'is_leader' => true,
                        ],
                        [
                            'name' => 'Alex Santos (You)',
                            'email' => 'alex.santos@student.edu',
                            'role' => 'Database Analyst',
                            'block' => 'BSIT 2B',
                            'avatar' => 'A',
                            'is_leader' => false,
                        ],
                        [
                            'name' => 'Hana Cruz',
                            'email' => 'hana.cruz@student.edu',
                            'role' => 'System Analyst',
                            'block' => 'BSIT 2B',
                            'avatar' => 'H',
                            'is_leader' => false,
                        ],
                        [
                            'name' => 'Bea Cruz',
                            'email' => 'bea.cruz@student.edu',
                            'role' => 'Data Modeler',
                            'block' => 'BSIT 2B',
                            'avatar' => 'B',
                            'is_leader' => false,
                        ],
                    ],
                ],
            ],
        ]);

        // Activity 4: Draft mode
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
            'formed_teams' => null,
        ]);
    }
}
