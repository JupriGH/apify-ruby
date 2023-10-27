require 'openssl'
require 'base64'
#require 'securerandom' # Python secrets.choice

module Apify

	class Crypto

		ENCRYPTION_KEY_LENGTH = 32
		ENCRYPTION_IV_LENGTH = 16
		ENCRYPTION_AUTH_TAG_LENGTH = 16

		SECURE_CHARS = [*'a'..'z', *'A'..'Z', *'0'..'9']
		
		"""Encrypts the given value using AES cipher and the password for encryption using the public key.

		The encryption password is a string of encryption key and initial vector used for cipher.
		It returns the encrypted password and encrypted value in BASE64 format.

		Args:
			value (str): The value which should be encrypted.
			public_key (RSAPublicKey): Public key to use for encryption.

		Returns:
			disc: Encrypted password and value.
		"""
		def self.public_encrypt value, public_key
			encryption_key = _crypto_random_object_id ENCRYPTION_KEY_LENGTH
			initialized_vector = _crypto_random_object_id ENCRYPTION_IV_LENGTH

			password_bytes = encryption_key + initialized_vector

			# NOTE: Auth Tag is appended to the end of the encrypted data, it has length of 16 bytes and ensures integrity of the data.

			cipher = OpenSSL::Cipher.new('aes-256-gcm')
			cipher.encrypt
			cipher.key = encryption_key
			cipher.iv_len = ENCRYPTION_IV_LENGTH # 16
			cipher.iv = initialized_vector
			
			encrypted_value = cipher.update(value) + cipher.final
			encrypted_password = public_key.public_encrypt(password_bytes, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
			
			# Base64 encode NOTE:
			# https://stackoverflow.com/questions/2620975/strange-n-in-base64-encoded-string-in-ruby
			return {
				encrypted_value: Base64.strict_encode64(encrypted_value + cipher.auth_tag),
				encrypted_password: Base64.strict_encode64(encrypted_password),
			}
		end

		"""Decrypts the given encrypted value using the private key and password.

		Args:
			encrypted_password (str): Password used to encrypt the private key encoded as base64 string.
			encrypted_value (str): Encrypted value to decrypt as base64 string.
			private_key (RSAPrivateKey): Private key to use for decryption.

		Returns:
			str: Decrypted value.
		"""		
		def self.private_decrypt encrypted_password, encrypted_value, private_key
			encrypted_password 	= Base64.decode64(encrypted_password)
			encrypted_value		= Base64.decode64(encrypted_value)

			# Decrypt the password
			password = private_key.private_decrypt(encrypted_password, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)

			raise 'Decryption failed, invalid password length!' unless # ValueError
				password.length == (ENCRYPTION_KEY_LENGTH + ENCRYPTION_IV_LENGTH) 
			
			# Slice the encrypted into cypher and authentication tag
			authentication_tag 		= encrypted_value[-ENCRYPTION_AUTH_TAG_LENGTH ..]
			encrypted_data 			= encrypted_value[.. -ENCRYPTION_AUTH_TAG_LENGTH-1]
			encryption_key 			= password[0, ENCRYPTION_KEY_LENGTH]
			initialization_vector 	= password[ENCRYPTION_KEY_LENGTH ..]
			
			begin
				cipher = OpenSSL::Cipher.new('aes-256-gcm')
				cipher.decrypt
				cipher.key  	= encryption_key
				cipher.iv_len	= ENCRYPTION_IV_LENGTH # 16
				cipher.iv   	= initialization_vector
				cipher.auth_tag	= authentication_tag

				# Perform decryption
				decipher_bytes = cipher.update(encrypted_data) + cipher.final

				return decipher_bytes

			rescue OpenSSL::Cipher::CipherError => exc # InvalidTagException:

			    raise 'Decryption failed, malformed encrypted value or password.' # ValueError
			end
		end

		def self._load_private_key private_key_file_base64, private_key_password # rsa.RSAPrivateKey    
			OpenSSL::PKey::RSA.new(
				Base64.urlsafe_decode64( private_key_file_base64 ), 
				private_key_password
			)
		rescue OpenSSL::PKey::RSAError
			raise 'Invalid public key.' # ValueError
		end

		def self._load_public_key public_key_file_base64 # rsa.RSAPrivateKey 
			OpenSSL::PKey::RSA.new(
				Base64.urlsafe_decode64( public_key_file_base64 ), 
			)
		rescue OpenSSL::PKey::RSAError
			raise 'Invalid public key.' # ValueError
		end

		"""Python reimplementation of cryptoRandomObjectId from `@apify/utilities`."""
		def self._crypto_random_object_id length=17
			# SecureRandom.send(:choose, SECURE_CHARS, length)
			length.times.map { SECURE_CHARS[OpenSSL::Random.random_bytes(1).unpack1('C') % SECURE_CHARS.length] }.join
		end

		"""Decrypt input secrets."""
		def self._decrypt_input_secrets private_key, input
			if input.class == Hash
				input.each do |key, value|	
					if value.class == String
						match = value.match(ENCRYPTED_INPUT_VALUE_REGEXP)
						if match
							input[key] = private_decrypt match[1], match[2], private_key
						end
					end
				end
			end
		end
	
	end
end