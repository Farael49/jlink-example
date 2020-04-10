package com.lab.jlink;

import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/book")
public class BookController {

    private final BookRepository bookRepository;

    public BookController(BookRepository bookRepository) {
        this.bookRepository = bookRepository;
    }

    @GetMapping
    public List<Book> getAllBooks(){
        return bookRepository.findAll();
    }

    @PostMapping
    public Book saveBook(@RequestBody Book book){
        return bookRepository.save(book);
    }

}
