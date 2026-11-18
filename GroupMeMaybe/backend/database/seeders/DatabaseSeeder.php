<?php

namespace Database\Seeders;

use App\Models\AcademicClass;
use App\Models\Activity;
use App\Models\CustomSkillRequest;
use App\Models\Notification;
use App\Models\Team;
use App\Models\TeamMember;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $password = Hash::make('password123');

        // 1. Professor User (Prof. Ghian Velasco)
        $prof = User::create([
            'id' => 'prof-1',
            'first_name' => 'Ghian',
            'last_name' => 'Velasco',
            'name' => 'Prof. Ghian Velasco',
            'email' => 'ghian.prof@university.edu',
            'password' => $password,
            'role' => 'professor',
            'student_id' => 'EMP-1001',
            'block' => 'Faculty of Computer Studies',
            'profile_status' => 'complete',
            'proficiency_rating' => 'advanced',
            'weekly_common_hours' => 20,
        ]);

        // 2. Student User: Alex Santos (Reference Photo Student)
        $alex = User::create([
            'id' => 'stud-alex',
            'first_name' => 'Alex',
            'last_name' => 'Santos',
            'name' => 'Alex Santos',
            'email' => 'alex.santos@university.edu',
            'password' => $password,
            'role' => 'student',
            'student_id' => '2023-10882',
            'block' => 'BSIT 2A',
            'profile_status' => 'complete',
            'proficiency_rating' => 'advanced',
            'weekly_common_hours' => 12,
            'technical_skills' => ['Frontend Development', 'UI/UX Design', 'Full-Stack Development'],
            'skill_levels' => ['Frontend Development' => 5, 'UI/UX Design' => 4, 'Full-Stack Development' => 4],
            'preferred_roles' => ['Project Leader / Team Leader', 'Frontend Developer', 'UI / UX Designer'],
            'interests' => ['Web Development', 'UI/UX and Creative Design', 'Mobile Apps'],
            'available_days' => ['Monday', 'Wednesday', 'Friday', 'Saturday'],
            'preferred_meeting_time' => 'Afternoon (1:00 PM - 5:00 PM)',
            'collaboration_mode' => 'Hybrid',
            'previous_experience' => 'Lead developer for academic projects, built multi-tier web applications.',
            'tools_and_technologies' => ['Flutter', 'React', 'HTML', 'CSS', 'Figma', 'Git', 'GitHub'],
            'assigned_team_id' => 'team-alpha-web',
        ]);

        // 3. Classmates
        $yvonne = User::create([
            'id' => 'stud-yvonne',
            'first_name' => 'Yvonne',
            'last_name' => 'Castro',
            'name' => 'Yvonne Castro',
            'email' => 'yvonne.c@university.edu',
            'password' => $password,
            'role' => 'student',
            'student_id' => '2023-10518',
            'block' => 'BSIT 2A',
            'profile_status' => 'complete',
            'proficiency_rating' => 'advanced',
            'weekly_common_hours' => 10,
            'technical_skills' => ['Backend Development', 'Database Management', 'Data Analysis'],
            'skill_levels' => ['Backend Development' => 5, 'Database Management' => 4],
            'preferred_roles' => ['Backend Developer', 'Database Administrator'],
            'interests' => ['Data and Analytics', 'Software Development'],
            'available_days' => ['Monday', 'Tuesday', 'Wednesday', 'Friday'],
            'assigned_team_id' => 'team-alpha-web',
        ]);

        $jansen = User::create([
            'id' => 'stud-jansen',
            'first_name' => 'Jansen',
            'last_name' => 'Mendoza',
            'name' => 'Jansen Mendoza',
            'email' => 'jansen.m@university.edu',
            'password' => $password,
            'role' => 'student',
            'student_id' => '2023-10450',
            'block' => 'BSIT 2A',
            'profile_status' => 'complete',
            'proficiency_rating' => 'intermediate',
            'weekly_common_hours' => 9,
            'technical_skills' => ['Frontend Development', 'API Development and Integration', 'UI/UX Design'],
            'skill_levels' => ['Frontend Development' => 4, 'UI/UX Design' => 4],
            'preferred_roles' => ['Frontend Developer', 'UI / UX Designer'],
            'interests' => ['Web Development', 'Mobile Apps'],
            'available_days' => ['Tuesday', 'Thursday', 'Saturday'],
            'assigned_team_id' => 'team-alpha-web',
        ]);

        $aivhan = User::create([
            'id' => 'stud-aivhan',
            'first_name' => 'Aivhan',
            'last_name' => 'Reyes',
            'name' => 'Aivhan Reyes',
            'email' => 'aivhan.r@university.edu',
            'password' => $password,
            'role' => 'student',
            'student_id' => '2023-10389',
            'block' => 'BSIT 2A',
            'profile_status' => 'incomplete',
            'proficiency_rating' => 'intermediate',
            'weekly_common_hours' => 6,
            'technical_skills' => ['Mobile App Development', 'Artificial Intelligence and Machine Learning'],
            'preferred_roles' => ['Mobile App Developer'],
            'interests' => ['Mobile Apps', 'AI and Machine Learning'],
            'available_days' => ['Monday', 'Wednesday'],
        ]);

        $jedrik = User::create([
            'id' => 'stud-jedrik',
            'first_name' => 'Jedrik',
            'last_name' => 'De Leon',
            'name' => 'Jedrik De Leon',
            'email' => 'jedrik.d@university.edu',
            'password' => $password,
            'role' => 'student',
            'student_id' => '2023-10221',
            'block' => 'BSIT 2A',
            'profile_status' => 'uninitialized',
            'proficiency_rating' => 'beginner',
            'weekly_common_hours' => 8,
            'technical_skills' => ['Database Management'],
            'preferred_roles' => ['Database Administrator'],
            'interests' => ['Data and Analytics'],
            'available_days' => ['Monday', 'Tuesday', 'Wednesday'],
        ]);

        $juliana = User::create([
            'id' => 'stud-juliana',
            'first_name' => 'Juliana',
            'last_name' => 'Santos',
            'name' => 'Juliana Santos',
            'email' => 'juliana.s@university.edu',
            'password' => $password,
            'role' => 'student',
            'student_id' => '2023-10492',
            'block' => 'BSIT 2A',
            'profile_status' => 'complete',
            'proficiency_rating' => 'advanced',
            'weekly_common_hours' => 12,
            'technical_skills' => ['Frontend Development', 'UI/UX Design', 'API Development and Integration'],
            'preferred_roles' => ['Project Leader / Team Leader', 'UI / UX Designer'],
            'interests' => ['Web Development', 'UI/UX and Creative Design'],
            'available_days' => ['Monday', 'Wednesday', 'Friday'],
        ]);

        $carlos = User::create([
            'id' => 'stud-carlos',
            'first_name' => 'Carlos',
            'last_name' => 'Ramos',
            'name' => 'Carlos Ramos',
            'email' => 'carlos.r@university.edu',
            'password' => $password,
            'role' => 'student',
            'student_id' => '2023-10672',
            'block' => 'BSIT 2A',
            'profile_status' => 'complete',
            'proficiency_rating' => 'intermediate',
            'weekly_common_hours' => 8,
            'technical_skills' => ['Database Management', 'Cloud Computing and DevOps'],
            'preferred_roles' => ['Database Administrator', 'DevOps Engineer'],
            'interests' => ['Cloud and Infrastructure', 'Data and Analytics'],
            'available_days' => ['Monday', 'Wednesday', 'Friday'],
        ]);

        $bea = User::create([
            'id' => 'stud-bea',
            'first_name' => 'Bea',
            'last_name' => 'Gonzales',
            'name' => 'Bea Gonzales',
            'email' => 'bea.g@university.edu',
            'password' => $password,
            'role' => 'student',
            'student_id' => '2023-10773',
            'block' => 'BSIT 2A',
            'profile_status' => 'complete',
            'proficiency_rating' => 'intermediate',
            'weekly_common_hours' => 10,
            'technical_skills' => ['Software Testing and Quality Assurance', 'Technical Documentation'],
            'preferred_roles' => ['QA / Software Tester', 'Technical Writer'],
            'interests' => ['Software Development', 'Project Management and Documentation'],
            'available_days' => ['Monday', 'Wednesday', 'Friday'],
        ]);

        // 4. Academic Classes
        $classWeb = AcademicClass::create([
            'id' => 'class-web',
            'code' => 'IT201',
            'name' => 'Web Development',
            'section' => 'BSIT 2A',
            'enrollment_code' => 'GMM-2011',
            'professor_id' => 'prof-1',
            'professor_name' => 'Prof. Ghian Velasco',
        ]);

        $classMobile = AcademicClass::create([
            'id' => 'class-mobile',
            'code' => 'CS302',
            'name' => 'Mobile Application Development',
            'section' => 'BSCS 3B',
            'enrollment_code' => 'GMM-3022',
            'professor_id' => 'prof-1',
            'professor_name' => 'Prof. Ghian Velasco',
        ]);

        $classDb = AcademicClass::create([
            'id' => 'class-db',
            'code' => 'IT202',
            'name' => 'Database Management Systems',
            'section' => 'BSIT 2B',
            'enrollment_code' => 'GMM-2023',
            'professor_id' => 'prof-1',
            'professor_name' => 'Prof. Ghian Velasco',
        ]);

        $classSec = AcademicClass::create([
            'id' => 'class-sec',
            'code' => 'CS404',
            'name' => 'Information Assurance & Security',
            'section' => 'BSCS 4A',
            'enrollment_code' => 'GMM-4044',
            'professor_id' => 'prof-1',
            'professor_name' => 'Prof. Ghian Velasco',
        ]);

        // Enroll students in class-web
        $studentIds = [$alex->id, $yvonne->id, $jansen->id, $aivhan->id, $jedrik->id, $juliana->id, $carlos->id, $bea->id];
        $classWeb->enrolledStudents()->attach($studentIds);
        $classMobile->enrolledStudents()->attach([$alex->id, $aivhan->id]);
        $classDb->enrolledStudents()->attach([$alex->id, $yvonne->id]);
        $classSec->enrolledStudents()->attach([$alex->id, $juliana->id]);

        // 5. Four Course Projects / Activities (Matching Reference Photo)
        $actCapstone = Activity::create([
            'id' => 'act-capstone',
            'class_id' => 'class-web',
            'class_name' => 'Web Development - BSIT 2A',
            'title' => 'Final Capstone Project',
            'description' => 'Design, build, and present a complete web application with dynamic database integration, responsive UI, and secure API endpoints.',
            'grouping_method' => 'hybrid',
            'group_capacity' => 5,
            'needed_groups' => 6,
            'min_common_hours' => 5,
            'required_skills' => ['Frontend Development', 'Backend Development', 'Database Management'],
            'preferred_skills' => ['API Development and Integration', 'UI/UX Design'],
            'grouping_deadline' => now()->addDays(4),
            'student_modification_deadline' => now()->addDays(6),
            'status' => 'open',
        ]);

        Activity::create([
            'id' => 'act-mobile',
            'class_id' => 'class-mobile',
            'class_name' => 'Mobile Application Development - BSCS 3B',
            'title' => 'Cross-Platform Mobile App Sprint',
            'description' => 'Develop a cross-platform mobile client with offline caching, push notifications, and clean UI/UX interaction flows.',
            'grouping_method' => 'auto',
            'group_capacity' => 4,
            'needed_groups' => 7,
            'min_common_hours' => 4,
            'required_skills' => ['Mobile App Development', 'API Development and Integration', 'UI/UX Design'],
            'preferred_skills' => ['Frontend Development'],
            'grouping_deadline' => now()->addDays(7),
            'student_modification_deadline' => now()->addDays(8),
            'status' => 'open',
        ]);

        Activity::create([
            'id' => 'act-schema',
            'class_id' => 'class-db',
            'class_name' => 'Database Management Systems - BSIT 2B',
            'title' => 'Enterprise Schema Modeling & Query Optimization',
            'description' => 'Form balanced teams to develop a normalized schema, migration scripts, and perform indexing and query profiling benchmarks.',
            'grouping_method' => 'manual',
            'group_capacity' => 4,
            'needed_groups' => 8,
            'min_common_hours' => 3,
            'required_skills' => ['Database Management', 'System Analysis and Design', 'Technical Documentation'],
            'preferred_skills' => ['Backend Development'],
            'grouping_deadline' => now()->subDay(),
            'student_modification_deadline' => now()->subDay(),
            'status' => 'open',
        ]);

        Activity::create([
            'id' => 'act-sec',
            'class_id' => 'class-sec',
            'class_name' => 'Information Assurance & Security - BSCS 4A',
            'title' => 'Network Vulnerability Audit & Defense Plan',
            'description' => 'Execute simulated penetration tests, packet inspection, and author a comprehensive mitigation roadmap for enterprise infrastructure.',
            'grouping_method' => 'auto',
            'group_capacity' => 5,
            'needed_groups' => 5,
            'min_common_hours' => 6,
            'required_skills' => ['Cybersecurity', 'Networking', 'Research and Problem Solving'],
            'preferred_skills' => ['Technical Documentation'],
            'grouping_deadline' => now()->addDays(10),
            'student_modification_deadline' => now()->addDays(12),
            'status' => 'open',
        ]);

        // 6. Seed Team: Team Alpha Web (3/5) (Matching Reference Photo)
        $teamAlpha = Team::create([
            'id' => 'team-alpha-web',
            'name' => 'Team Alpha Web',
            'activity_id' => 'act-capstone',
            'class_id' => 'class-web',
            'leader_id' => 'stud-alex',
            'capacity' => 5,
            'is_confirmed' => false,
            'is_student_formed' => true,
            'is_auto_filled' => false,
            'skill_coverage' => 92.0,
            'interest_match' => 85.0,
            'availability_overlap' => 80.0,
            'overall_compatibility' => 86.0,
        ]);

        TeamMember::create([
            'team_id' => $teamAlpha->id,
            'user_id' => $alex->id,
            'name' => $alex->name,
            'block' => $alex->block,
            'assigned_role' => 'Project Leader / Full-Stack',
            'is_locked' => true,
            'weekly_common_hours' => 12,
            'skills' => $alex->technical_skills,
            'interests' => $alex->interests,
            'available_days' => $alex->available_days,
            'skill_levels' => $alex->skill_levels,
        ]);

        TeamMember::create([
            'team_id' => $teamAlpha->id,
            'user_id' => $yvonne->id,
            'name' => $yvonne->name,
            'block' => $yvonne->block,
            'assigned_role' => 'Backend Developer',
            'is_locked' => true,
            'weekly_common_hours' => 10,
            'skills' => $yvonne->technical_skills,
            'interests' => $yvonne->interests,
            'available_days' => $yvonne->available_days,
            'skill_levels' => $yvonne->skill_levels,
        ]);

        TeamMember::create([
            'team_id' => $teamAlpha->id,
            'user_id' => $jansen->id,
            'name' => $jansen->name,
            'block' => $jansen->block,
            'assigned_role' => 'Frontend Developer',
            'is_locked' => true,
            'weekly_common_hours' => 9,
            'skills' => $jansen->technical_skills,
            'interests' => $jansen->interests,
            'available_days' => $jansen->available_days,
            'skill_levels' => $jansen->skill_levels,
        ]);

        // 7. Seed Custom Skill Request & Notification
        CustomSkillRequest::create([
            'id' => 'skill-req-1',
            'student_id' => 'stud-alex',
            'student_name' => 'Alex Santos',
            'skill_name' => 'GraphQL API Integration',
            'category' => 'Web Development',
            'justification' => 'Essential for modern high-performance microservice querying in capstone.',
            'status' => 'pending',
            'date_requested' => now()->subHours(2),
        ]);

        Notification::create([
            'id' => 'notif-1',
            'recipient_id' => 'all',
            'title' => 'Final Capstone Project Grouping Active',
            'message' => 'Manual team formation deadline ends in 4 days. Unassigned students will be processed via Hybrid Formation.',
            'type' => 'deadlineReminder',
            'is_read' => false,
            'timestamp' => now(),
        ]);
    }
}
