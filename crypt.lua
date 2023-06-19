local b = beamer
local floor = math.floor

local function xor (a,b)
  local r = 0
  for i = 0, 31 do
    local x = a / 2 + b / 2

    if x ~= floor (x) then
      r = r + 2^i
    end

    a = floor (a / 2)
    b = floor (b / 2)
  end

  return r

end

function b.lib.encrypt(phrase, public_key)
    local private_key = os.time() % 256
    local encrypted_pass_one = ""
    local encrypted_pass_two = ""
    local chr = ""
    local string_len = string.len(phrase)

    for idx = string_len, 1, -1 do
        chr = xor(string.byte(phrase,idx), private_key)
        encrypted_pass_one = encrypted_pass_one .. string.char(chr)

    end

    encrypted_pass_one = encrypted_pass_one .. string.char(private_key)

    for idx = 1, string_len + 1 do
        chr = xor(string.byte(encrypted_pass_one,idx), public_key)
        encrypted_pass_two = encrypted_pass_two .. string.char(chr)

    end

    return encrypted_pass_two

end

function b.lib.decrypt(phrase, public_key)
    local decrypted_pass_one = ""
    local decrypted_pass_two = ""
    local chr = ""
    local string_len = string.len(phrase)

    for idx = 1, string_len do
        chr = xor(string.byte(phrase,idx), public_key)
        decrypted_pass_two = decrypted_pass_two .. string.char(chr)

    end

    local private_key = string.byte(decrypted_pass_two, string.len(decrypted_pass_two))

    for idx = string_len - 1, 1, -1 do
        chr = xor(string.byte(decrypted_pass_two,idx), private_key)
        decrypted_pass_one = decrypted_pass_one .. string.char(chr)

    end

    return decrypted_pass_one

end
