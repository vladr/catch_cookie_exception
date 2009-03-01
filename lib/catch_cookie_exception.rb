require 'cgi'
require 'cgi/session'
class CGI::Session::CookieStore
  # Restore session data from the cookie.
  # This method overrides the one in 
  # actionpack/lib/action_controller/session/cookie_store.rb
  # in order to handle the case of a "tampered" cookie more gracefully.
  # The issue is that changing the 'secret' in config/environment.rb
  # breaks all sessions in such a way that everyone gets an error page
  # the first time they revisit the site.  Catching the exception here
  # prevents this ugly behavior.
  # This is in a plugin so that it loads after Rails but before environment.rb.

  def restore_with_catch
    restore_without_catch
  rescue CGI::Session::CookieStore::TamperedWithCookie
    logger = defined?(::RAILS_DEFAULT_LOGGER) ? ::RAILS_DEFAULT_LOGGER : Logger.new($stderr)
    env = @session && @session.cgi && @session.cgi.respond_to?(:env_table) && @session.cgi.__send__(:env_table)
    logger.warn "Possible session hijack attempt on #{Time.now} from #{@session && @session.cgi && @session.cgi.remote_addr || 'unknown remote address'}:\n#{env ? env.keys.sort.collect { |k| sprintf("  %-25s: %s\n", k, env[k]) } : 'no request environment information is available'}"
    @data = {}
  end

  alias_method_chain :restore, :catch

end