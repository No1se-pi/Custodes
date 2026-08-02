#!/usr/bin/env python3
"""Совместимая точка входа для старых установок и shell-модуля check."""

from custodes.cli import main

if __name__ == "__main__":
    raise SystemExit(main())
