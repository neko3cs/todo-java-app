package com.example.todo.service;

import com.example.todo.domain.Todo;
import com.example.todo.repository.TodoRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class TodoService {
    private final TodoRepository repo;

    public TodoService(TodoRepository repo) { this.repo = repo; }

    public List<Todo> findAll() { return repo.findAll(); }
    public Optional<Todo> findById(UUID id) { return repo.findById(id); }
    public Todo save(Todo todo) { return repo.save(todo); }
    public void deleteById(UUID id) { repo.deleteById(id); }
}
