local b = beamer
local key_network = b.key_network

function b.lib.encrypt(phrase, public_key)
    local private_key = os.time() % 255
    local crypted_pass_one = ""
    local crypted_pass_two = ""
    local char = ""
    local string_len = string.len(phrase)

    for idx = string_len, 1, -1 do
        char = string.byte(phrase,idx) ~ private_key
        crypted_pass_one = crypted_pass_one .. string.char(char)

    end

    crypted_pass_one = crypted_pass_one .. string.char(private_key)

    for idx = 1, string_len + 1 do
        char = string.byte(crypted_pass_one,idx) ~ public_key
        crypted_pass_two = crypted_pass_two .. string.char(char)

    end

    return crypted_pass_two

end

function b.lib.decrypt(phrase, public_key)
    local crypted_pass_one = ""
    local crypted_pass_two = ""
    local char = ""
    local string_len = string.len(phrase)

    for idx = 1, string_len do
        char = string.byte(phrase,idx) ~ public_key
        crypted_pass_two = crypted_pass_two .. string.char(char)

    end

    private_key = string.byte(crypted_pass_two, string.len(crypted_pass_two))

    for idx = string_len - 1, 1, -1 do
        char = string.byte(crypted_pass_two,idx) ~ private_key
        crypted_pass_one = crypted_pass_one .. string.char(char)

    end

    crypted_pass_one = crypted_pass_one
    return crypted_pass_one

end
