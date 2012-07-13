#encoding: utf-8

require 'unicode'
require 'date'

def month_name month
    month = month.to_i if month.instance_of? String
    [ 'январь', 'февраль', 'март', 'апрель', 'май', 'июнь', 'июль', 
      'август', 'сентябрь', 'октябрь', 'ноябрь', 'декабрь' ][ month - 1 ]
end

def month_s month
    month = month.to_i if month.instance_of? String
    month < 10 ? '0' + month.to_s : month.to_s
end

class Date
    class << self
        def now
            n = Time.now
            self.new n.year, n.month, n.day
        end

        def months_last_day year, month
            d = Date.new year.to_i, month.to_i
            d = ( d >> 1 ) - 1
            self.new d.year, d.month, d.day
        end
   end
end

class String
    def downcase
        Unicode::downcase self
    end

    def downcase!
        self.replace downcase
    end

    def upcase
        Unicode::upcase self
    end

    def upcase!
        self.replace upcase
    end

    def capitalize
        Unicode::capitalize self
    end

    def capitalize!
        self.replace capitalize
    end
end
