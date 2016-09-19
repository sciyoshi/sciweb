---
title: Writing Python Extension Modules in Rust
published: false
description: 
mathjax: true
---

Python is an amazing language - it's my tool of choice for most programming tasks because of its expressive power, readability, and vibrant and helpful community.

However, when it comes to performance, Python isn't normally the first language to come to mind. While it's great for many use cases, as an interpreted language it can't compare to native code for CPU-heavy workloads. There are a number of efforts under way to improve this - in particular, [PyPy's JIT]() can offer reasonable speedups without any changes to your code, by dynamically compiling it at runtime. Still, many systems are reliant on the CPython interpreter, so being able to write optimized modules is important.

Fortunately, Python provides a [C extending/embedding API]() which lets us do just that. Once you drop down to writing C, however, you need to pay attention to a lot more things. To avoid memory leaks, [reference counting]() for Python objects needs to be done manually. Also, because C lacks an exception system, errors are handled by checking for `NULL` return values on each function call. Needless to say, this can be error-prone and time-consuming when debugging.

Enter Rust, a modern, strongly-typed, compiled language meant for writing highly safe and efficient code. I've been excited about Rust for some time now as an alternative to C/C++ because it provides:

- Memory and type safety: no more worrying about dereferencing a `NULL` pointer or accessing freed memory. With Rust, ownership of data is a language construct, and memory is freed automatically when it goes out of scope.
- Zero-cost abstractions: Rust provides high-level constructs like iterators and closures, without incurring any runtime cost from dynamic dispatch or garbage collection.
- Powerful macros: rather than a text-based preprocessor like C, Rust has macros which operate on the parsed syntax tree.

Having memory safety guarantees baked into the language mean that you no longer have to worry about segfaults or use-after-free. And although there is a learning curve, the compiler normally provides helpful explanations to guide you. There is much more to Rust than what I've presented here - you should check out the [official documentation]() for the full details.

These qualities make Rust a great option for writing high-performance Python extension modules.

## Lucas Sequences

In this post we'll be looking at how to write an extension module to compute Lucas numbers (actually, linear recurrences), which are extensions of Fibonacci numbers to different starting values. To be precise, given coefficients we will compute a sequence $a\_n$ of numbers defined by the recurrence relation $$a\_{n+k} = \sum\_{i=0}^{k-1} c\_i a\_{n + i}$$ for initial values $a\_0, a\_1, ... a\_{k-1}$ and coefficients $c\_0, c\_1, ... c\_{k-1}$.

## Defining a Module

Native CPython modules are actually shared libraries (normally, `.so` or `.dll`) that export a specially-named function which acts as the module initializer. 
When the Python interpreter attemps to import a native module, it first loads the library (with `dlopen()` or `LoadLibrary()`), then runs this function with an empty module object that then gets installed into `sys.modules`. The function name is `PyInit_<modulename>` (or `init<modulename>` on Python 2).

In Rust, making a function callable from C normally involves specifying the calling convention and exporting a symbol. However, the bindings take care of this for us with a macro:

```rust
py_module_initializer!(lucas, initlucas, PyInit_lucas, |py, module| {
    /* module initialization code goes here */

    Ok(())
});
```

The first argument is our module's name, the next two are the function names for Python 2 and 3, and the third is the body of the initialization function, which will get called with a `module` object. (Ignore the `py` argument for now - we'll get to that later.)

## Adding a Class

`rust-cpython` also comes with a [macro that lets you easily create Python classes](http://dgrunwald.github.io/rust-cpython/doc/cpython/macro.py_class!.html). You can define data items on the class, which are added to the underlying Rust struct. By default, these are inaccessible from Python unless you explicitly add accessor methods.

In this example, we want to create a Python iterator. In order to calculate the next value in the sequence, it needs to store the list of coefficients, and the past $n$ values in the sequence. The code then looks like this:

```
py_class!(class LucasIter |py| {
        data coef: Vec<i64>;
        data vals: RefCell<VecDeque<i64>>;

        def __iter__(&self) -> PyResult<LucasIter> {
                Ok(self.clone_ref(py))
        }

        def __next__(&self) -> PyResult<Option<i64>> {
                let mut vals = self.vals(py).borrow_mut();
                let next = self.coef(py).iter().zip(vals.iter()).map(|(a, b)| a * b).sum();

                vals.push_back(next);

                Ok(Some(vals.pop_front().unwrap()))
        }
});
```

The two data items are `coef` and `vals`. We need to use a [`RefCell`]() to get [interior mutability](). To compute the dot product, the coefficients are zipped with the vector of previous values, then each element is multiplied before summing.

### Ownership and Reference Counting

One big advantage of using Rust is that reference counting is handled automatically by the type system. When an (owned) Python object in Rust goes out of scope, its `Drop` implementation decrements the reference count. When ownership is taken, the assumption is that the CPython reference has been passed. What that means is that there is no need to manually handle these references, unlike C's calls to `Py_INCREF/DECREF`. If a function takes a borrow, then the reference count is incremented during its lifetime (see [`from_borrowed_ptr`]()).

### Lifetimes and the GIL

Python has a (oft-maligned) mechanism called the Global Interpreter Lock, or GIL, which prevents multiple native threads from concurrently accessing the interpreter. When writing native extension modules, any operation which modifies interpreter state needs to be holding this global mutex. In C code called from Python, you can already assume that the GIL is held. Before doing a blocking or long-running operation, it's good practice to release this lock to allow other interpreter threads to run.

In the Rust bindings, the mechanism for acquiring and releasing this lock is handled using [lifetimes](). The `py` variable we saw above signals that the GIL is held for the duration of its scope. Similarly, the GIL can be acquired manually using [RAII]() with `Python::acquire_gil()`. Any functions which require the GIL (like getting Python types, or accessing fields) will require this parameter to be passed.

## Defining a Function

Let's add a simple function to our module to return an instance of our `LucasIter` class. FIXME

## Making it Distributable

Defining dependencies in a Rust project is done with a `Cargo.toml` file. [Cargo]() is Rust's package manager, and handles downloading and compiling dependencies for you. 

```
[package]
name = "lucas"
version = "0.0.1"
authors = ["Samuel Cormier-Iijima <sciyoshi@gmail.com>"]

[dependencies]
cpython = { git = "https://github.com/dgrunwald/rust-cpython" }

[lib]
name = "lucas"
crate-type = ["dylib"]
```

This defines a Cargo "crate" named `lucas`, and adds the [Rust CPython bindings] as a dependency. It also tells Cargo to build a shared dynamic library (dylib) from the file `src/lucas.rs`.

We also need to import these macros and make them available within the file:

```rust
#[macro_use]
extern crate cpython;
```

At this point, we can build an importable library simply by running `cargo build` - but we can do better! We can use the [Rust extensions for setuptools]() to create installable Python packages. To do this, we'll create a `setup.py` file:

```python
from setuptools import setup, dist

dist.Distribution(dict(setup_requires=['rust-ext==0.1']))

from rust_ext import build_rust_cmdclass, install_lib_including_rust

setup(
    name='lucas',
    version='0.1',
    description='Lucas sequences',
    author='Samuel Cormier-Iijima',
    author_email='sciyoshi@gmail.com',
    cmdclass={
        'build_rust': build_rust_cmdclass('Cargo.toml'),
        'install_lib': install_lib_including_rust
    },
    zip_safe=False)
```

There's a few things to notice here. We first create an explicit distribution which depends on the `rust-ext` package. This lets others run `setup.py` without needing to install the package manually. We then use `build_rust_cmdclass` and `install_lib_including_rust` to override the `setup.py install` command to build the library with Cargo.

## Conclusion

We've seen how to use `rust-cpython` to create native Python extensions in Rust. These bindings are an excellent way to get started optimizing specific bits of slow Python code. There are other approaches to calling out to Rust from Python that I haven't mentioned here, including using `cffi` and `ctypes`. [Dan Callahan]() gave a great talk about this at PyCon in Montreal, and it's a great alternative to using the Python bindings directly.
