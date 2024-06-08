--[[

The MIT License (MIT)
Copyright (C) 2024 Flay Krunegan

Permission is hereby granted, free of charge, to any person obtaining a copy of this
software and associated documentation files (the "Software"), to deal in the Software
without restriction, including without limitation the rights to use, copy, modify, merge,
publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
DEALINGS IN THE SOFTWARE.

]]

local function show_form(name, text, result, option)
    minetest.show_formspec(name, "encode_form",
        "size[8,7.4]" ..
        "label[0,0;Enter the text to encode/decode:]"..
        "box[-0.1,-0.1;8,0.7;#020202]"..
        "field[0.3,1.5;8,1;text;Input:;" .. text .. "]" ..
        "dropdown[0,2.5;8.4,1;option;Text to Binary,Binary to Text,Text to Morse,Morse to Text,Binary to Morse,Morse to Binary;" .. option .. "]" ..
        "box[0,4;7.77,3.35;#030303]" ..
        "textarea[0.3,4;8,4;;Output:;" .. result .. "]"
    )
end

local function is_valid_input(input)
    local cleaned_input = input:gsub("[\",';]", "")
    return cleaned_input:match("^[A-Za-z0-9%s%p]+$") ~= nil
end

local function text_to_binary(text)
    local result = ""
    if not is_valid_input(text) then
        return "Invalid input. Please only use letters, basic symbols, numbers, and spaces."
    end
    for i = 1, #text do
        local byte = string.byte(text, i)
        for j = 7, 0, -1 do
            result = result .. tostring(bit.band(byte, 2^j) > 0 and 1 or 0)
        end
        result = result .. " "
    end
    return result
end

local function binary_to_text(binary)
    local text = ""
    if not binary:match("^[01 ]+$") then
        return "Error: Binary text should only contain 0, 1, and spaces."
    end

    for byte_str in binary:gmatch("[01]+") do
        local byte = 0
        for i = 1, #byte_str do
            byte = byte * 2 + tonumber(byte_str:sub(i, i))
        end
        local char = string.char(byte)
        if char:match("[,;'\"`]") then
            char = ""
        end
        text = text .. char
    end
    return text
end

local function text_to_morse(text)
    local morse_code = {
        ['A'] = '.-', ['B'] = '-...', ['C'] = '-.-.', ['D'] = '-..', ['E'] = '.', ['F'] = '..-.', ['G'] = '--.',
        ['H'] = '....', ['I'] = '..', ['J'] = '.---', ['K'] = '-.-', ['L'] = '.-..', ['M'] = '--', ['N'] = '-.',
        ['O'] = '---', ['P'] = '.--.', ['Q'] = '--.-', ['R'] = '.-.', ['S'] = '...', ['T'] = '-',
        ['U'] = '..-', ['V'] = '...-', ['W'] = '.--', ['X'] = '-..-', ['Y'] = '-.--', ['Z'] = '--..',
        ['1'] = '.----', ['2'] = '..---', ['3'] = '...--', ['4'] = '....-', ['5'] = '.....',
        ['6'] = '-....', ['7'] = '--...', ['8'] = '---..', ['9'] = '----.', ['0'] = '-----',
        [' '] = '/'
    }

    local morse_text = ""
    for char in text:gmatch(".") do
        local upperChar = char:upper()
        if morse_code[upperChar] then
            morse_text = morse_text .. morse_code[upperChar] .. " "
        else
            morse_text = morse_text .. char .. " "
        end
    end
    return morse_text
end

local function morse_to_text(morse)
    local morse_code = {
        ['.'] = 'A', ['-'] = 'B', ['.-'] = 'C', ['--'] = 'D', ['.'] = 'E', ['..-.'] = 'F', ['--.'] = 'G',
        ['....'] = 'H', ['..'] = 'I', ['.---'] = 'J', ['-.-'] = 'K', ['.-..'] = 'L', ['--'] = 'M', ['-.'] = 'N',
        ['---'] = 'O', ['.---.'] = 'P', ['--.-'] = 'Q', ['.-.'] = 'R', ['...'] = 'S', ['-'] = 'T',
        ['..-'] = 'U', ['...-'] = 'V', ['.--'] = 'W', ['-..-'] = 'X', ['-.--'] = 'Y', ['--..'] = 'Z',
        ['.----'] = '1', ['..---'] = '2', ['...--'] = '3', ['....-'] = '4', ['.....'] = '5',
        ['-....'] = '6', ['--...'] = '7', ['---..'] = '8', ['----.'] = '9', ['-----'] = '0',
        ['/'] = ' '
    }

    local text = ""
    for word in morse:gmatch("[^/]+") do
        for char in word:gmatch("[^%s]+") do
            if morse_code[char] then
                text = text .. morse_code[char]
            else
                text = text .. char
            end
        end
        text = text .. " "
    end
    return text
end

local function binary_to_morse(binary)
    local binary_to_text_result = binary_to_text(binary)
    if binary_to_text_result:match("Error:") then
        return binary_to_text_result
    end

    local text_to_morse_result = text_to_morse(binary_to_text_result)
    return text_to_morse_result
end

local function morse_to_binary(morse)
    local morse_to_text_result = morse_to_text(morse)
    if morse_to_text_result:match("Error:") then
        return morse_to_text_result
    end

    local text_to_binary_result = text_to_binary(morse_to_text_result)
    return text_to_binary_result
end

minetest.register_chatcommand("enc", {
    params = "",
    description = "Open encoding form",
    func = function(name, param)
        show_form(name, "", "", "Text to Binary")
    end,
})

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "encode_form" then
        local text = fields.text or ""
        local option = fields.option or ""
        local result = ""

        if fields.quit then
            minetest.close_formspec(player:get_player_name(), "encode_form")
        elseif option == "Text to Binary" then
            result = text_to_binary(text)
            show_form(player:get_player_name(), text, result, "Text to Binary")
        elseif option == "Binary to Text" then
            result = binary_to_text(text)
            show_form(player:get_player_name(), text, result, "Binary to Text")
        elseif option == "Text to Morse" then
            result = text_to_morse(text)
            show_form(player:get_player_name(), text, result, "Text to Morse")
        elseif option == "Morse to Text" then
            result = morse_to_text(text)
            show_form(player:get_player_name(), text, result, "Morse to Text")
        elseif option == "Binary to Morse" then
            result = binary_to_morse(text)
            show_form(player:get_player_name(), text, result, "Binary to Morse")
        elseif option == "Morse to Binary" then
            result = morse_to_binary(text)
            show_form(player:get_player_name(), text, result, "Morse to Binary")
        end
    end
end)
