module SonicPiAkaiApcMini
  module SPThreadSafeRange
    def __sp_make_thread_safe
      (self.begin.__sp_make_thread_safe..self.end.__sp_make_thread_safe).freeze
    end

    def sp_thread_safe?
      frozen? && self.begin.sp_thread_safe? && self.end.sp_thread_safe?
    end
  end
end

Range.prepend SonicPiAkaiApcMini::SPThreadSafeRange
