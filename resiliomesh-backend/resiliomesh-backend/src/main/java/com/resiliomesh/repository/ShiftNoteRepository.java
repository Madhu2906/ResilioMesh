package com.resiliomesh.repository;

import com.resiliomesh.model.ShiftNoteEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ShiftNoteRepository extends JpaRepository<ShiftNoteEntity, Long> {}