class TlsTesterUtilTestClass
	include Inferno::Utils::TlsTester
end 

RSpec.describe Inferno::Utils::TlsTester do 
	let(:tester) ()
	# Create a tls_tester class giving a good uri and good host/port
	# Create a tls_tester class giving a bad uri but good host/port
	# Create a tls_tester class giving a good uri but bad host/port
	# Create a tls_tester class giving a bad uri but good host/and bad port
	# Create a tls_tester class giving a bad uri but bad host/and bad port

end
