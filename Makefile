.PHONY: lint
lint: 
	lua lint.lua $(filter-out config%.lua, $(wildcard *.lua))
