package com.resiliomesh.controller;

import com.resiliomesh.model.ShiftNoteEntity;
import com.resiliomesh.repository.ShiftNoteRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/v1/notes")
@CrossOrigin(origins = "*")
public class ShiftNoteController {

    @Autowired
    private ShiftNoteRepository noteRepository;

    @GetMapping
    public List<ShiftNoteEntity> getAllNotes() {
        return noteRepository.findAll();
    }

    @PostMapping
    public ShiftNoteEntity saveNote(@RequestBody ShiftNoteEntity note) {
        note.setTimestamp(String.valueOf(System.currentTimeMillis()));
        return noteRepository.save(note);
    }
}