package com.example.todo.controller;

import com.example.todo.domain.Status;
import com.example.todo.domain.Todo;
import com.example.todo.service.TodoService;
import jakarta.validation.Valid;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.validation.BindingResult;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.UUID;

@Controller
@RequestMapping("/todos")
public class TodoController {
    private final TodoService service;

    public TodoController(TodoService service) { this.service = service; }

    @GetMapping
    public String list(Model model) {
        model.addAttribute("todos", service.findAll());
        return "index";
    }

    @GetMapping("/new")
    public String createForm(Model model) {
        model.addAttribute("todo", new Todo());
        model.addAttribute("statuses", Status.values());
        return "form";
    }

    @PostMapping
    public String create(@Valid @ModelAttribute("todo") Todo todo, BindingResult br) {
        if (br.hasErrors()) return "form";
        service.save(todo);
        return "redirect:/todos";
    }

    @GetMapping("/{id}/edit")
    public String editForm(@PathVariable UUID id, Model model) {
        var t = service.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Todo not found"));
        model.addAttribute("todo", t);
        model.addAttribute("statuses", Status.values());
        return "form";
    }

    @PostMapping("/{id}")
    public String update(@PathVariable UUID id, @Valid @ModelAttribute("todo") Todo todo, BindingResult br) {
        if (br.hasErrors()) return "form";
        todo.setId(id);
        service.save(todo);
        return "redirect:/todos";
    }

    @GetMapping("/{id}")
    public String detail(@PathVariable UUID id, Model model) {
        var t = service.findById(id).orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Todo not found"));
        model.addAttribute("todo", t);
        return "detail";
    }

    @PostMapping("/{id}/delete")
    public String delete(@PathVariable UUID id) {
        service.deleteById(id);
        return "redirect:/todos";
    }
}
