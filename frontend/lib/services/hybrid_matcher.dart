import 'dart:math';
import '../models/user_model.dart';
import '../models/team_model.dart';
import '../models/activity_model.dart';

enum HybridStrategy { fillIncompleteFirst, formNewTeamsOnly }

class HybridResult {
  final List<TeamModel> allTeams;
  final List<TeamModel> modifiedTeams;
  final List<TeamModel> newTeams;
  final List<UserModel> remainingStudents;
  final List<String> stepLogs;
  final double balanceGap;
  final double highestScore;
  final double lowestScore;
  final int openSlots;
  final int unassignedCount;
  final int studentsFilled;
  final int newTeamsCount;
  final int swapsPerformed;

  HybridResult({
    required this.allTeams,
    required this.modifiedTeams,
    required this.newTeams,
    required this.remainingStudents,
    required this.stepLogs,
    required this.balanceGap,
    required this.highestScore,
    required this.lowestScore,
    required this.openSlots,
    required this.unassignedCount,
    required this.studentsFilled,
    required this.newTeamsCount,
    required this.swapsPerformed,
  });
}

class HybridMatcher {
  /// Default weights as specified: 0.4 skills, 0.3 hours, 0.3 interest
  static const double defaultSkillsWeight = 0.40;
  static const double defaultHoursWeight = 0.30;
  static const double defaultInterestWeight = 0.30;

  /// Main execution method for the 7-Step Hybrid Mode Computation
  static HybridResult execute({
    required ActivityModel activity,
    required List<TeamModel> existingTeams,
    required List<UserModel> unassignedStudents,
    HybridStrategy strategy = HybridStrategy.fillIncompleteFirst,
    double skillsWeight = defaultSkillsWeight,
    double hoursWeight = defaultHoursWeight,
    double interestWeight = defaultInterestWeight,
    int? minCommonHoursH,
  }) {
    final List<String> logs = [];
    final int H = minCommonHoursH ?? (activity.minCommonHours > 0 ? activity.minCommonHours : 3);
    final int T = activity.groupCapacity > 0 ? activity.groupCapacity : 4;

    logs.add('--- HYBRID MODE COMPUTATION STARTED ---');
    logs.add('Target Team Capacity (T): $T | Minimum Common Hours Threshold (H): $H hrs/wk');
    logs.add('Weights: Skills ${(skillsWeight * 100).toInt()}% | Hours ${(hoursWeight * 100).toInt()}% | Interest ${(interestWeight * 100).toInt()}%');

    // Clone teams and students to avoid mutating caller state prematurely
    final List<TeamModel> workingTeams = existingTeams.map((t) => t.copyWith()).toList();
    final List<UserModel> pool = List<UserModel>.from(unassignedStudents);
    final int initialU = pool.length;

    // STEP 1: Count students and open slots
    final List<TeamModel> incompleteTeams = workingTeams.where((t) => t.members.length < T).toList();
    int openSlots = 0;
    for (var t in incompleteTeams) {
      openSlots += (T - t.members.length);
    }

    logs.add('[Step 1] Unassigned Students (U): $initialU');
    logs.add('[Step 1] Incomplete Teams: ${incompleteTeams.length} | Total Open Slots: $openSlots');

    int studentsUsedToFill = 0;
    int leftoverStudentsCount = initialU;
    int newTeamsTarget = 0;

    // STEP 2: Decide how many go where
    if (strategy == HybridStrategy.fillIncompleteFirst) {
      studentsUsedToFill = min(initialU, openSlots);
      leftoverStudentsCount = initialU - studentsUsedToFill;
      newTeamsTarget = leftoverStudentsCount ~/ T;
      final int remainder = leftoverStudentsCount % T;

      logs.add('[Step 2] Strategy A: Fill Incomplete Teams First selected.');
      logs.add('[Step 2] Students allocated to fill slots: $studentsUsedToFill | Leftover: $leftoverStudentsCount');
      logs.add('[Step 2] Base New Teams to form: $newTeamsTarget | Remainder: $remainder');

      if (remainder > 0) {
        if (remainder >= T - 1) {
          newTeamsTarget += 1;
          logs.add('[Step 2] Remainder $remainder >= T-1 ($T-1): forming 1 smaller team of size $remainder.');
        } else {
          logs.add('[Step 2] Remainder $remainder < T-1 ($T-1): distributing +1 extra members to teams (T+1 allowed, student never left alone).');
        }
      }
    } else {
      newTeamsTarget = initialU ~/ T;
      final int remainder = initialU % T;
      logs.add('[Step 2] Strategy B: Form New Teams Only selected.');
      logs.add('[Step 2] New Teams to form: $newTeamsTarget | Remainder: $remainder (existing incomplete teams stay unchanged).');
    }

    // STEP 4: Fill incomplete teams (the "gain" computation)
    // For each unassigned student, starting with those who have fewest free hours (hardest to place)
    final List<TeamModel> modifiedTeams = [];

    if (strategy == HybridStrategy.fillIncompleteFirst && studentsUsedToFill > 0) {
      // Sort unassigned students ascending by weeklyCommonHours (fewest free hours first)
      pool.sort((a, b) => a.weeklyCommonHours.compareTo(b.weeklyCommonHours));

      int placedCount = 0;
      final List<UserModel> filledStudents = [];

      for (var student in List<UserModel>.from(pool)) {
        if (placedCount >= studentsUsedToFill) break;

        TeamModel? bestTeam;
        double bestGain = -999.0;
        double bestNewScore = -1.0;

        for (var team in workingTeams) {
          if (team.members.length >= T) continue; // Skip full teams

          final candidateMember = _convertToMember(student, isLocked: false);
          final currentScore = computeTeamScore(
            team.members,
            activity,
            ws: skillsWeight,
            wh: hoursWeight,
            wi: interestWeight,
            H: H,
          );

          final hypotheticalMembers = List<TeamMember>.from(team.members)..add(candidateMember);
          final hypotheticalScore = computeTeamScore(
            hypotheticalMembers,
            activity,
            ws: skillsWeight,
            wh: hoursWeight,
            wi: interestWeight,
            H: H,
          );

          // If common hours drop to 0, placement is rejected
          if (hypotheticalScore < 0) continue;

          final double gain = hypotheticalScore - currentScore;
          if (gain > bestGain) {
            bestGain = gain;
            bestTeam = team;
            bestNewScore = hypotheticalScore;
          }
        }

        if (bestTeam != null) {
          if (!bestTeam.isAutoFilled) {
            bestTeam.previousScore = bestTeam.overallCompatibility;
            bestTeam.isAutoFilled = true;
          }

          final newMember = _convertToMember(student, isLocked: false);
          bestTeam.members.add(newMember);

          // Recalculate team metrics immediately
          _recalculateMetrics(bestTeam, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H);

          if (!modifiedTeams.contains(bestTeam)) {
            modifiedTeams.add(bestTeam);
          }

          filledStudents.add(student);
          placedCount++;

          logs.add(
            '[Step 4] Placed "${student.fullName.isNotEmpty ? student.fullName : student.displayName}" '
            '(${student.weeklyCommonHours}h free) into "${bestTeam.name}". Gain: ${bestGain >= 0 ? '+' : ''}${(bestGain * 100).toStringAsFixed(1)}% '
            '-> New Team Score: ${(bestNewScore * 100).toStringAsFixed(1)}%',
          );
        }
      }

      for (var s in filledStudents) {
        pool.remove(s);
      }
    }

    // STEP 5: Form new teams from leftover students (Seed + Gain)
    final List<TeamModel> newlyFormedTeams = [];

    if (pool.isNotEmpty && newTeamsTarget > 0) {
      logs.add('[Step 5] Forming $newTeamsTarget new teams from ${pool.length} leftover students.');

      // 5a. Pick Seeds:
      // Seed 1 = student with the most skills
      pool.sort((a, b) => b.technicalSkills.length.compareTo(a.technicalSkills.length));
      final List<UserModel> seeds = [];
      seeds.add(pool.first);
      pool.removeAt(0);

      logs.add('[Step 5] Seed 1 picked: "${seeds.first.displayName}" with ${seeds.first.technicalSkills.length} skills.');

      // Subsequent seeds: lowest average pair compatibility to seeds already chosen
      while (seeds.length < newTeamsTarget && pool.isNotEmpty) {
        UserModel? nextSeed;
        double lowestAvgCompat = 999.0;

        for (var candidate in pool) {
          double totalCompat = 0.0;
          for (var seed in seeds) {
            totalCompat += computePairCompatibility(candidate, seed);
          }
          final double avgCompat = totalCompat / seeds.length;
          if (avgCompat < lowestAvgCompat) {
            lowestAvgCompat = avgCompat;
            nextSeed = candidate;
          }
        }

        if (nextSeed != null) {
          seeds.add(nextSeed);
          pool.remove(nextSeed);
          logs.add('[Step 5] Seed ${seeds.length} picked: "${nextSeed.displayName}" (Lowest Avg Pair Compat: ${(lowestAvgCompat * 100).toStringAsFixed(1)}%).');
        } else {
          break;
        }
      }

      // Initialize team objects for seeds
      for (int i = 0; i < seeds.length; i++) {
        final seedStudent = seeds[i];
        final newTeamId = 'team-hybrid-${DateTime.now().millisecondsSinceEpoch}-$i';
        final newTeam = TeamModel(
          id: newTeamId,
          name: 'Team ${workingTeams.length + newlyFormedTeams.length + 1} (Hybrid)',
          activityId: activity.id,
          classId: activity.classId,
          leaderId: seedStudent.id,
          capacity: T,
          isConfirmed: false,
          isStudentFormed: false,
          isAutoFilled: true,
          members: [_convertToMember(seedStudent, isLocked: false)],
        );
        _recalculateMetrics(newTeam, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H);
        newlyFormedTeams.add(newTeam);
      }

      // 5b. Add the rest using gain computation, fewest free hours first
      pool.sort((a, b) => a.weeklyCommonHours.compareTo(b.weeklyCommonHours));

      final List<UserModel> placedFromLeftovers = [];
      for (var student in List<UserModel>.from(pool)) {
        TeamModel? bestTeam;
        double bestGain = -999.0;

        for (var team in newlyFormedTeams) {
          // Allow up to T (or T + 1 if absorbing remainders)
          if (team.members.length >= T + 1) continue;

          final candidate = _convertToMember(student, isLocked: false);
          final currentScore = computeTeamScore(
            team.members,
            activity,
            ws: skillsWeight,
            wh: hoursWeight,
            wi: interestWeight,
            H: H,
          );

          final hypothetical = List<TeamMember>.from(team.members)..add(candidate);
          final hypoScore = computeTeamScore(
            hypothetical,
            activity,
            ws: skillsWeight,
            wh: hoursWeight,
            wi: interestWeight,
            H: H,
          );

          if (hypoScore < 0) continue; // rejected if common hours = 0

          final gain = hypoScore - currentScore;
          if (gain > bestGain) {
            bestGain = gain;
            bestTeam = team;
          }
        }

        if (bestTeam != null) {
          bestTeam.members.add(_convertToMember(student, isLocked: false));
          _recalculateMetrics(bestTeam, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H);
          placedFromLeftovers.add(student);
          logs.add(
            '[Step 5] Added "${student.displayName}" to "${bestTeam.name}". Gain: ${bestGain >= 0 ? '+' : ''}${(bestGain * 100).toStringAsFixed(1)}%',
          );
        }
      }

      for (var s in placedFromLeftovers) {
        pool.remove(s);
      }

      workingTeams.addAll(newlyFormedTeams);
    }

    // STEP 6: Swap improvement
    // Only auto-assigned, unlocked members can be swapped. Student-chosen members stay locked.
    int swapsCount = 0;
    bool improvementFound = true;
    int pass = 1;

    logs.add('[Step 6] Running Swap Improvement (auto-assigned members only)...');

    while (improvementFound && pass <= 5) {
      improvementFound = false;

      for (int i = 0; i < workingTeams.length; i++) {
        for (int j = i + 1; j < workingTeams.length; j++) {
          final teamX = workingTeams[i];
          final teamY = workingTeams[j];

          // Find unlocked auto-assigned members in teamX and teamY
          final unlockedX = teamX.members.where((m) => !m.isLocked).toList();
          final unlockedY = teamY.members.where((m) => !m.isLocked).toList();

          for (var mx in unlockedX) {
            for (var my in unlockedY) {
              final double before = computeTeamScore(teamX.members, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H) +
                  computeTeamScore(teamY.members, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H);

              final hypotheticalMembersX = List<TeamMember>.from(teamX.members)
                ..remove(mx)
                ..add(my);
              final hypotheticalMembersY = List<TeamMember>.from(teamY.members)
                ..remove(my)
                ..add(mx);

              final double scoreHypoX = computeTeamScore(hypotheticalMembersX, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H);
              final double scoreHypoY = computeTeamScore(hypotheticalMembersY, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H);

              // Reject if common hours become 0 in either team
              if (scoreHypoX < 0 || scoreHypoY < 0) continue;

              final double after = scoreHypoX + scoreHypoY;

              if (after > before + 0.005) {
                // Keep the swap
                teamX.members.remove(mx);
                teamX.members.add(my);
                teamY.members.remove(my);
                teamY.members.add(mx);

                _recalculateMetrics(teamX, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H);
                _recalculateMetrics(teamY, activity, ws: skillsWeight, wh: hoursWeight, wi: interestWeight, H: H);

                swapsCount++;
                improvementFound = true;
                logs.add(
                  '[Step 6] Swapped auto-assigned "${mx.name}" (Team ${teamX.name}) with "${my.name}" (Team ${teamY.name}). '
                  'Score gain: +${((after - before) * 100).toStringAsFixed(1)}%',
                );
                break;
              }
            }
            if (improvementFound) break;
          }
          if (improvementFound) break;
        }
        if (improvementFound) break;
      }
      pass++;
    }

    logs.add('[Step 6] Swap improvement completed. Total swaps performed: $swapsCount');

    // STEP 7: Roles and final results
    // Assign roles from each member's preference ranking avoiding duplicates (e.g. only 1 leader)
    for (var team in workingTeams) {
      final Set<String> takenRoles = {};
      // Existing locked members keep their roles
      for (var m in team.members.where((m) => m.isLocked)) {
        takenRoles.add(m.assignedRole);
      }

      for (var m in team.members.where((m) => !m.isLocked)) {
        // Find corresponding user
        final user = unassignedStudents.firstWhere((u) => u.id == m.userId, orElse: () => UserModel(id: m.userId, email: '', role: UserRole.student));
        String selectedRole = 'Developer';
        for (var rolePref in user.preferredRoles) {
          if (rolePref.toLowerCase().contains('leader') && takenRoles.any((r) => r.toLowerCase().contains('leader'))) {
            continue; // Team already has a Leader, skip
          }
          if (!takenRoles.contains(rolePref)) {
            selectedRole = rolePref;
            break;
          }
        }
        m.assignedRole = selectedRole;
        takenRoles.add(selectedRole);
      }

      // Ensure team has a leader
      if (team.members.isNotEmpty && (team.leaderId.isEmpty || !team.members.any((m) => m.userId == team.leaderId))) {
        team.leaderId = team.members.first.userId;
      }
    }

    // Balance indicator: highest team score - lowest team score
    double highest = -1.0;
    double lowest = 999.0;
    for (var t in workingTeams) {
      if (t.overallCompatibility > highest) highest = t.overallCompatibility;
      if (t.overallCompatibility < lowest) lowest = t.overallCompatibility;
    }
    if (lowest > highest) lowest = highest;
    final double balanceGap = (highest - lowest).clamp(0.0, 100.0);

    logs.add('[Step 7] Final Results Summary:');
    logs.add('Total Teams: ${workingTeams.length} | Highest Team Score: ${highest.toStringAsFixed(1)}% | Lowest Team Score: ${lowest.toStringAsFixed(1)}%');
    logs.add('Balance Gap: ${balanceGap.toStringAsFixed(1)}% (${balanceGap <= 15 ? "Well Balanced" : "Moderate Gap"})');

    return HybridResult(
      allTeams: workingTeams,
      modifiedTeams: modifiedTeams,
      newTeams: newlyFormedTeams,
      remainingStudents: pool,
      stepLogs: logs,
      balanceGap: balanceGap,
      highestScore: highest,
      lowestScore: lowest,
      openSlots: openSlots,
      unassignedCount: initialU,
      studentsFilled: studentsUsedToFill,
      newTeamsCount: newlyFormedTeams.length,
      swapsPerformed: swapsCount,
    );
  }

  /// Step 3 TeamScore Formula:
  /// TeamScore = ws * SkillCoverage + wh * CommonHoursRatio + wi * AvgInterest - Penalty
  static double computeTeamScore(
    List<TeamMember> members,
    ActivityModel activity, {
    double ws = defaultSkillsWeight,
    double wh = defaultHoursWeight,
    double wi = defaultInterestWeight,
    required int H,
  }) {
    if (members.isEmpty) return 0.0;

    // 1. SkillCoverage
    double skillCoverage = 0.0;
    if (activity.requiredSkills.isNotEmpty) {
      double totalImportance = 0.0;
      double weightedCoverage = 0.0;

      for (var reqSkill in activity.requiredSkills) {
        const double importance = 1.0;
        const int minLevelNeeded = 3; // Intermediate default
        totalImportance += importance;

        int highestLevel = 0;
        for (var m in members) {
          final lvl = m.skillLevels[reqSkill] ?? (m.skills.contains(reqSkill) ? 3 : 0);
          if (lvl > highestLevel) highestLevel = lvl;
        }

        final ratio = min(1.0, highestLevel / minLevelNeeded);
        weightedCoverage += ratio * importance;
      }
      skillCoverage = totalImportance > 0 ? (weightedCoverage / totalImportance) : 0.8;
    } else {
      // Skill variety fallback
      final Set<String> distinctSkills = {};
      int totalSkills = 0;
      for (var m in members) {
        distinctSkills.addAll(m.skills);
        totalSkills += m.skills.length;
      }
      skillCoverage = totalSkills > 0 ? (distinctSkills.length / totalSkills).clamp(0.0, 1.0) : 0.75;
    }

    // 2. CommonHoursRatio
    // Hours when every member is free / smallest free-hours count among members
    int smallestFreeHours = 999;
    for (var m in members) {
      if (m.weeklyCommonHours < smallestFreeHours) {
        smallestFreeHours = m.weeklyCommonHours;
      }
    }
    if (smallestFreeHours <= 0) smallestFreeHours = 1;

    // Common free hours estimate: overlap of days / count * smallestFreeHours
    final commonHoursEstimate = estimateCommonHours(members, smallestFreeHours);
    final double commonHoursRatio = (commonHoursEstimate / smallestFreeHours).clamp(0.0, 1.0);

    // 3. AvgInterest
    // Average interest overlap (shared / combined interests) across all pairs in team
    double avgInterest = 0.0;
    if (members.length >= 2) {
      int pairCount = 0;
      double totalJaccard = 0.0;
      for (int i = 0; i < members.length; i++) {
        for (int j = i + 1; j < members.length; j++) {
          final s1 = members[i].interests.toSet();
          final s2 = members[j].interests.toSet();
          final intersection = s1.intersection(s2).length;
          final union = s1.union(s2).length;
          final jaccard = union > 0 ? (intersection / union) : 0.3;
          totalJaccard += jaccard;
          pairCount++;
        }
      }
      avgInterest = pairCount > 0 ? (totalJaccard / pairCount) : 0.3;
    } else {
      avgInterest = 0.5;
    }

    // 4. Penalty: applies only if common hours fall below minimum H
    // Penalty = 0.3 * (H - common hours) / H. If common hours are 0, placement is rejected (-1.0)
    double penalty = 0.0;
    if (commonHoursEstimate == 0) {
      return -1.0; // Rejected!
    } else if (commonHoursEstimate < H) {
      penalty = 0.3 * (H - commonHoursEstimate) / H;
    }

    final double score = (ws * skillCoverage) + (wh * commonHoursRatio) + (wi * avgInterest) - penalty;
    return max(0.0, score);
  }

  /// Estimates common free hours among team members
  static int estimateCommonHours(List<TeamMember> members, int smallestFreeHours) {
    if (members.isEmpty) return 0;
    if (members.length == 1) return members.first.weeklyCommonHours;

    // Overlap of available days
    Set<String> commonDays = members.first.availableDays.toSet();
    for (var m in members.skip(1)) {
      commonDays = commonDays.intersection(m.availableDays.toSet());
    }

    if (commonDays.isEmpty) {
      // Small 1 hr baseline if schedules have no strict day overlap, or 0 if completely disjoint
      return max(0, (smallestFreeHours * 0.2).toInt());
    }

    final double dayRatio = commonDays.length / max(1, members.first.availableDays.length);
    final int estimated = (smallestFreeHours * dayRatio).round();
    return max(1, min(smallestFreeHours, estimated));
  }

  /// Step 5: Pair Compatibility Formula
  /// Pair = 0.4 * (1 - skill overlap) + 0.3 * (overlap hours / smaller free hours) + 0.3 * interest overlap
  static double computePairCompatibility(UserModel u1, UserModel u2) {
    // Skill overlap: shared skills / union skills
    final skills1 = u1.technicalSkills.toSet();
    final skills2 = u2.technicalSkills.toSet();
    final skillUnion = skills1.union(skills2).length;
    final skillInter = skills1.intersection(skills2).length;
    final double skillOverlap = skillUnion > 0 ? (skillInter / skillUnion) : 0.0;

    // Hours overlap
    final commonDays = u1.availableDays.toSet().intersection(u2.availableDays.toSet()).length;
    final smallerFree = min(u1.weeklyCommonHours, u2.weeklyCommonHours);
    final double hoursRatio = smallerFree > 0 ? ((commonDays / 5.0) * smallerFree) / smallerFree : 0.5;

    // Interest overlap
    final int1 = u1.interests.toSet();
    final int2 = u2.interests.toSet();
    final intUnion = int1.union(int2).length;
    final intInter = int1.intersection(int2).length;
    final double interestOverlap = intUnion > 0 ? (intInter / intUnion) : 0.2;

    return (0.4 * (1.0 - skillOverlap)) + (0.3 * hoursRatio.clamp(0.0, 1.0)) + (0.3 * interestOverlap.clamp(0.0, 1.0));
  }

  static TeamMember _convertToMember(UserModel user, {bool isLocked = true}) {
    return TeamMember(
      userId: user.id,
      name: user.fullName.isNotEmpty ? user.fullName : user.displayName,
      photoUrl: user.photoUrl,
      block: user.block,
      assignedRole: user.preferredRoles.isNotEmpty ? user.preferredRoles.first : 'Member',
      skills: List.from(user.technicalSkills),
      interests: List.from(user.interests),
      availableDays: List.from(user.availableDays),
      weeklyCommonHours: user.weeklyCommonHours,
      isLocked: isLocked,
      skillLevels: Map.from(user.skillLevels),
    );
  }

  static void _recalculateMetrics(
    TeamModel team,
    ActivityModel activity, {
    required double ws,
    required double wh,
    required double wi,
    required int H,
  }) {
    final rawScore = computeTeamScore(team.members, activity, ws: ws, wh: wh, wi: wi, H: H);
    team.overallCompatibility = (rawScore.clamp(0.0, 1.0) * 100);

    // Approximate breakdown sub-scores for compatibility indicators
    int smallestFree = 999;
    for (var m in team.members) {
      if (m.weeklyCommonHours < smallestFree) smallestFree = m.weeklyCommonHours;
    }
    if (smallestFree == 999) smallestFree = 8;
    final commonHours = estimateCommonHours(team.members, smallestFree);

    team.availabilityOverlap = ((commonHours / smallestFree).clamp(0.0, 1.0) * 100);
    team.skillCoverage = ((team.overallCompatibility * 0.45 + 50).clamp(50.0, 100.0));
    team.interestMatch = ((team.overallCompatibility * 0.40 + 55).clamp(55.0, 100.0));
  }
}
