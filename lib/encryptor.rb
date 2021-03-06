require 'openssl'
require 'encryptor/string'

String.send(:include, Encryptor::String)

# A simple wrapper for the standard OpenSSL library
module Encryptor
  autoload :Version, 'encryptor/version'

  extend self

  # The default options to use when calling the <tt>encrypt</tt> and <tt>decrypt</tt> methods
  #
  # Defaults to { :algorithm => 'aes-256-cbc' }
  #
  # Run 'openssl list-cipher-commands' in your terminal to view a list all cipher algorithms that are supported on your platform
  def default_options
    @default_options ||= { :algorithm => 'aes-256-cbc' }
  end

  # Encrypts a <tt>:value</tt> with a specified <tt>:key</tt>
  #
  # Optionally accepts <tt>:iv</tt> and <tt>:algorithm</tt> options
  #
  # Example
  #
  #   encrypted_value = Encryptor.encrypt(:value => 'some string to encrypt', :key => 'some secret key')
  #   # or
  #   encrypted_value = Encryptor.encrypt('some string to encrypt', :key => 'some secret key')
  def encrypt(*args, &block)
    crypt :encrypt, *args, &block
  end

  # Decrypts a <tt>:value</tt> with a specified <tt>:key</tt>
  #
  # Optionally accepts <tt>:iv</tt> and <tt>:algorithm</tt> options
  #
  # Example
  #
  #   decrypted_value = Encryptor.decrypt(:value => 'some encrypted string', :key => 'some secret key')
  #   # or
  #   decrypted_value = Encryptor.decrypt('some encrypted string', :key => 'some secret key')
  def decrypt(*args, &block)
    crypt :decrypt, *args, &block
  end

  protected

    def crypt(cipher_method, *args) #:nodoc:
      options = default_options.merge(:value => args.first).merge(args.last.is_a?(Hash) ? args.last : {})
      raise ArgumentError.new('must specify a :key') if options[:key].to_s.empty?
      cipher = OpenSSL::Cipher::Cipher.new(options[:algorithm])
      cipher.send(cipher_method)
      if options[:iv]
        cipher.key = options[:key]
        cipher.iv = options[:iv]
      else
        cipher.pkcs5_keyivgen(options[:key])
      end
      yield cipher, options if block_given?
      result = cipher.update(options[:value])
      result << cipher.final
    end
end