#!/bin/bash
ollama serve &

sleep 5

ollama run llama3 &

wait