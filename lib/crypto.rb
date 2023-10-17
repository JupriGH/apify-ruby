require 'openssl'
require 'base64'

module Apify

class Crypto

=begin
import secrets
from typing import Any

from cryptography.exceptions import InvalidTag as InvalidTagException
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes

from apify_shared.utils import ignore_docs

from .consts import ENCRYPTED_INPUT_VALUE_REGEXP
=end

	ENCRYPTION_KEY_LENGTH = 32
	ENCRYPTION_IV_LENGTH = 16
	ENCRYPTION_AUTH_TAG_LENGTH = 16


	BASE64_REGEXP = '[-A-Za-z0-9+/]*={0,3}'
	ENCRYPTED_INPUT_VALUE_PREFIX = 'ENCRYPTED_VALUE'
	ENCRYPTED_INPUT_VALUE_REGEXP = Regexp.new "^#{ENCRYPTED_INPUT_VALUE_PREFIX}:(#{BASE64_REGEXP}):(#{BASE64_REGEXP})$"

=begin

@ignore_docs
def public_encrypt(value: str, *, public_key: rsa.RSAPublicKey) -> dict:
    """Encrypts the given value using AES cipher and the password for encryption using the public key.

    The encryption password is a string of encryption key and initial vector used for cipher.
    It returns the encrypted password and encrypted value in BASE64 format.

    Args:
        value (str): The value which should be encrypted.
        public_key (RSAPublicKey): Public key to use for encryption.

    Returns:
        disc: Encrypted password and value.
    """
    key_bytes = _crypto_random_object_id(ENCRYPTION_KEY_LENGTH).encode('utf-8')
    initialized_vector_bytes = _crypto_random_object_id(ENCRYPTION_IV_LENGTH).encode('utf-8')
    value_bytes = value.encode('utf-8')

    password_bytes = key_bytes + initialized_vector_bytes

    # NOTE: Auth Tag is appended to the end of the encrypted data, it has length of 16 bytes and ensures integrity of the data.
    cipher = Cipher(algorithms.AES(key_bytes), modes.GCM(initialized_vector_bytes, min_tag_length=ENCRYPTION_AUTH_TAG_LENGTH))
    encryptor = cipher.encryptor()
    encrypted_value_bytes = encryptor.update(value_bytes) + encryptor.finalize()
    encrypted_password_bytes = public_key.encrypt(
        password_bytes,
        padding.OAEP(
            mgf=padding.MGF1(algorithm=hashes.SHA1()),
            algorithm=hashes.SHA1(),
            label=None,
        ),
    )
    return {
        'encrypted_value': base64.b64encode(encrypted_value_bytes + encryptor.tag).decode('utf-8'),
        'encrypted_password': base64.b64encode(encrypted_password_bytes).decode('utf-8'),
    }
=end


	def self.private_decrypt encrypted_password, encrypted_value, private_key
		"""Decrypts the given encrypted value using the private key and password.

		Args:
			encrypted_password (str): Password used to encrypt the private key encoded as base64 string.
			encrypted_value (str): Encrypted value to decrypt as base64 string.
			private_key (RSAPrivateKey): Private key to use for decryption.

		Returns:
			str: Decrypted value.
		"""

		encrypted_password 	= Base64.decode64(encrypted_password) # .encode('utf-8')
		encrypted_value		= Base64.decode64(encrypted_value) # .encode('utf-8')

		# Decrypt the password
		password = private_key.private_decrypt(encrypted_password, OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)

		raise 'Decryption failed, invalid password length!' if password.length != ( ENCRYPTION_KEY_LENGTH + ENCRYPTION_IV_LENGTH ) # ValueError
		
		# Slice the encrypted into cypher and authentication tag
		authentication_tag		= encrypted_value[-ENCRYPTION_AUTH_TAG_LENGTH ..]
		encrypted_data 			= encrypted_value[.. -ENCRYPTION_AUTH_TAG_LENGTH-1]	    
		encryption_key 			= password[0, ENCRYPTION_KEY_LENGTH]
		initialization_vector 	= password[ENCRYPTION_KEY_LENGTH ..]

		#try:
			#cipher = Cipher(algorithms.AES(encryption_key_bytes), modes.GCM(initialization_vector_bytes, authentication_tag_bytes))
			#decryptor = cipher.decryptor()
			#decipher_bytes = decryptor.update(encrypted_data_bytes) + decryptor.finalize()

			cipher = OpenSSL::Cipher.new("aes-256-gcm")
			cipher.decrypt
			cipher.key 			= encryption_key
			cipher.iv_len		= initialization_vector.length # 16
			cipher.iv 			= initialization_vector
			cipher.auth_tag 	= authentication_tag

			# Perform decryption
			decipher_bytes = cipher.update(encrypted_data) + cipher.final
			
			# .decode('utf-8')
			return decipher_bytes

		#except InvalidTagException:
		#    raise ValueError('Decryption failed, malformed encrypted value or password.')
		#except Exception as err:
		#    raise err

		# return decipher_bytes.decode('utf-8')
	end

	def self._load_private_key private_key_file_base64, private_key_password # rsa.RSAPrivateKey    
		OpenSSL::PKey::RSA.new(
			Base64.urlsafe_decode64( private_key_file_base64 ), 
			private_key_password
		)
		
		# if not isinstance(private_key, rsa.RSAPrivateKey):
		#    raise ValueError('Invalid private key.')
	end

=begin
def _load_public_key(public_key_file_base64: str) -> rsa.RSAPublicKey:
    public_key = serialization.load_pem_public_key(base64.b64decode(public_key_file_base64.encode('utf-8')))
    if not isinstance(public_key, rsa.RSAPublicKey):
        raise ValueError('Invalid public key.')

    return public_key


def _crypto_random_object_id(length: int = 17) -> str:
    """Python reimplementation of cryptoRandomObjectId from `@apify/utilities`."""
    chars = 'abcdefghijklmnopqrstuvwxyzABCEDFGHIJKLMNOPQRSTUVWXYZ0123456789'
    return ''.join(secrets.choice(chars) for _ in range(length))

=end

	def self._decrypt_input_secrets private_key, input
		"""Decrypt input secrets."""

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