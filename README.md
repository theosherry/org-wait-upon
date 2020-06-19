# Org Wait Upon

This package adds the ability to set which tasks WAITING tasks are waiting upon.

Adds links to and from blocking and waiting tasks are added to properties drawer of relevent headings, and when all blocking tasks are finished, waiting tasks are set as TODO.

## Installation

Clone the repo and add `org-wait-upon.el` to your load path.

## Usage

`(org-wait-upon-init)`

Then when setting a task to WAITING, you will be prompted whether or not you want to wait upon specific tasks.

## Dependencies

- `helm`
- `helm-org`
- `dash`
- `s`

## Roadmap

- [ ] allow customization of heading statuses that can form waiting-blocking relationship
- [ ] allow cross-file relationships and let user customize which files should be searched for candidates
- [ ] fix issue with org-id-get-create taking too long
- [ ] add nicer formatting to candidate selection buffers
- [ ] work with ido
- [ ] work with ivy
- [ ] allow user to specify which completion engine to use (helm, ido or ivy)
- [ ] publish on melpa
