require 'ffi'

module RPM
  module C

    extend ::FFI::Library

    begin
      ffi_lib ['librpm-5.4.so','librpm.so.7','librpm.so.3', 'librpm.so.2', 'librpm.so.1' 'rpm']
    rescue LoadError => e
      raise(
        "Can't find rpm libs on your system: #{e.message}"
      )
    end

    attach_function 'rpmvercmp', [:string, :string], :int

  end
end
