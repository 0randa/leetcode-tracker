package dev.lctracker.backend.repo

import dev.lctracker.backend.domain.Problem
import dev.lctracker.backend.domain.ReviewSession
import dev.lctracker.backend.domain.Tag
import dev.lctracker.backend.domain.UserProgress
import dev.lctracker.backend.domain.UserTopicComfort
import org.springframework.data.jpa.repository.JpaRepository

interface ProblemRepository : JpaRepository<Problem, Long> {
    fun findBySlug(slug: String): Problem?
}

interface TagRepository : JpaRepository<Tag, Long> {
    fun findByName(name: String): Tag?
}

interface UserProgressRepository : JpaRepository<UserProgress, Long> {
    fun findByUserIdAndProblem_Id(userId: Long, problemId: Long): UserProgress?
    fun findByUserId(userId: Long): List<UserProgress>
}

interface UserTopicComfortRepository : JpaRepository<UserTopicComfort, Long> {
    fun findByUserId(userId: Long): List<UserTopicComfort>
}

interface ReviewSessionRepository : JpaRepository<ReviewSession, Long> {
    fun findByUserIdAndProblem_IdOrderByCreatedAtDesc(userId: Long, problemId: Long): List<ReviewSession>
    fun findByUserId(userId: Long): List<ReviewSession>
}
