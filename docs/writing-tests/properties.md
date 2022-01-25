---
title: Test Properties
nav_order: 2
parent: Writing Tests
---
# Test/Suite/Group Properties
{: .no_toc}

## Table of Contents
{: .no_toc .text-delta}

1. TOC
{:toc}
---
## Title
The title which is displayed in the UI:
```ruby
test do
  title 'US Core Patient Read Interaction'
end
```
[`title` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#title-instance_method)

## Id
A unique identifier for a test/group/suite. Inferno will automatically create
ids if they are not specified. It is important to create ids yourself if you
need to refer to a test/group elsewhere, such as to include one in another
group.
```ruby
test do
  id :us_core_patient_read
end

group do
  test from: :us_core_patient_read
end
```
[`id` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#id-instance_method)

## Description
A detailed description which is displayed in the UI.
[Markdown](https://commonmark.org/help/) is supported. There are several ways to
define long strings in ruby:

```ruby
test do
  description 'This is a brief description'
  
  description 'This is a longer description. There are several ways to split ' \
              'it up over multiple lines, and this is one of the worst ways.'
              
  description <<~DESCRIPTION
    This is another long description. This is an ok way to represent a long
    string in ruby.
  DESCRIPTION
  
  description %(
    This is another long description. This is a pretty good way to represent a
    long string in ruby.
  )
end
```
[`description` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#description-instance_method)

## Optional/Required
Mark a test/group as optional/required. Tests/Groups are required by default.
The results of optional tests do not affect the test result of their parent.

```ruby
group do
  optional # Makes this group optional

  test do
    optional # Makes this test optional
  end
  
  test from: :some_optional_test do
    required # Make an optional test required
  end
end
```
[`optional` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#optional-instance_method)

[`required` in the API
docs](/inferno-core/docs/Inferno/DSL/Runnable.html#required-instance_method)

## Run
(`Test`s only) `run` defines a block of code which is executed when the test is
run. A test will typically make one or more
[assertions](/inferno-core/docs/Inferno/DSL/Assertions.html). If no assertions fail, then the
test passes.
```ruby
test do
  run do
    assert 1 == 0, 'One is not equal to zero'
  end
end
```
[`run` in the API
docs](/inferno-core/docs/Inferno/Entities/Test.html#block-class_method)
