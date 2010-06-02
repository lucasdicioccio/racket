#field.rb

=begin

This file is part of Racket.

Racket is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Racket is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Racket.  If not, see <http://www.gnu.org/licenses/>.

Copyright (c) 2009, Lucas Di Cioccio

=end

module Racket

  class FieldDefinition
    attr_reader :name, :default_value

    def initialize(name, dflt=nil)
      @name, @default_value = name, dflt
    end
  end

  # dynamic fields #

  class DynamicFieldDefinition < FieldDefinition
  end

  # standard fields #

  class RawFieldDefinition < FieldDefinition
    attr_reader :pack_atom
    def initialize(name, atom, dflt=nil)
      super(name, dflt)
      @pack_atom = atom
    end
  end

  class StandardFieldDefinition < RawFieldDefinition
    def size
      self.class.size
    end
  end

  class Char < StandardFieldDefinition
    @size = 1
    def initialize(name, dflt)
      super(name, 'c', dflt)
    end
  end

  class HexPair < StandardFieldDefinition
    @size = 1
    def initialize(name, dflt)
      super(name, 'H2', dflt)
    end
  end

  # emtpy fields #

  class EmptyFieldDefinition < FieldDefinition
  end

  class MissingFieldDefinition < FieldDefinition
  end

  class SkippedFieldDefinition < EmptyFieldDefinition
  end
end
