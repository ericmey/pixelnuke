# Contributing to Pixelnuke

Thank you for your interest in contributing to Pixelnuke!

## Development Setup

### Prerequisites

- macOS or Linux
- ARM cross-compiler (`aarch64-none-elf-gcc` or `aarch64-linux-gnu-gcc`)
- Git
- clang-format and cppcheck (for code quality checks)

### Getting Started

```bash
# Clone with submodules
git clone --recursive https://github.com/yourusername/pixelnuke.git
cd pixelnuke

# Configure Circle framework
cd circle && ./configure -r 3 -p aarch64-none-elf-
cd ..

# Build libraries (first time)
make -C src/bootloader libs

# Build and check
make -C src/bootloader check
make -C src/bootloader
```

## Code Style

- **Tabs**: 8 spaces (embedded convention, enforced by .clang-format)
- **Line length**: Max 100 characters
- **Naming**: Circle conventions (CClassName, m_MemberVar, nLocalVar)

Run `make format` to auto-format your code.

## Before Submitting

### Required Checks

```bash
# All must pass
make -C src/bootloader check   # Format + lint
make -C src/bootloader         # Build
```

### Hardware Testing

If your changes affect:
- Boot sequence
- Network code
- Partition handling
- Any hardware drivers

You must test on real Pi Zero 2 W hardware.

### Documentation

- Update `/docs/` for user-facing changes
- Update component README for technical changes
- Keep CLAUDE.md current for AI-assisted development

## Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run all checks (`make check`)
5. Test on hardware (if applicable)
6. Update documentation
7. Commit with descriptive message
8. Push to your fork
9. Open a Pull Request

## Commit Messages

Use clear, descriptive commit messages:

```
Add TFTP firmware upload support

- Implement CTFTPBootServer with authentication prefix
- Add file size validation
- Update documentation

Co-Authored-By: Your Name <your@email.com>
```

## Project Structure

```
docs/       → User documentation (keep updated)
dev/        → Internal development notes
src/        → Source code
boot/       → SD card setup scripts
openocd/    → Debug configurations
```

## Questions?

Open an issue for:
- Bug reports
- Feature requests
- Questions about the codebase

## License

By contributing, you agree that your contributions will be licensed under the project's license.
