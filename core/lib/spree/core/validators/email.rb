class EmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    warn "`EmailValidator` in 'lib/spree/core' is deprecated. Use `EmailValidator` in 'app/validators' instead."
    unless value =~ %r{\A(([A-Za-z0-9]+_+)|
                          ([A-Za-z0-9]+\-+)|
                          ([A-Za-z0-9]+\.+)|
                          ([A-Za-z0-9]+\++))*[A-Za-z0-9_]+@((\w+\-+)|
                          (\w+\.))*\w{1,63}\.[a-zA-Z]{2,6}\z}xi
      record.errors.add(attribute, :invalid, { value: value }.merge!(options))
    end
  end
end
