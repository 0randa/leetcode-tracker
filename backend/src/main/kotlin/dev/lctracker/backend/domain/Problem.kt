package dev.lctracker.backend.domain

import jakarta.persistence.Column
import jakarta.persistence.Entity
import jakarta.persistence.EnumType
import jakarta.persistence.Enumerated
import jakarta.persistence.Id
import jakarta.persistence.JoinColumn
import jakarta.persistence.JoinTable
import jakarta.persistence.ManyToMany
import jakarta.persistence.Table

/**
 * Catalogue entry. The numeric LeetCode id is the assigned primary key (not
 * generated) so upstream slug/title renames never orphan a user's progress.
 */
@Entity
@Table(name = "problems")
class Problem(
    @Id
    val id: Long,

    @Column(nullable = false, unique = true)
    var slug: String,

    @Column(nullable = false)
    var title: String,

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 10)
    var difficulty: Difficulty,

    @Column(name = "is_active", nullable = false)
    var isActive: Boolean = true,

    @Column(name = "is_neetcode_150", nullable = false)
    var isNeetcode150: Boolean = false,

    @ManyToMany
    @JoinTable(
        name = "problem_tags",
        joinColumns = [JoinColumn(name = "problem_id")],
        inverseJoinColumns = [JoinColumn(name = "tag_id")],
    )
    var tags: MutableSet<Tag> = mutableSetOf(),
)
