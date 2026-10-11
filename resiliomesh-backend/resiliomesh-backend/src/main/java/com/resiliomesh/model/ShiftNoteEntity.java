package com.resiliomesh.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "shift_notes")
@Data
public class ShiftNoteEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String author;
    @Column(length = 1000)
    private String note;
    private String timestamp;
}