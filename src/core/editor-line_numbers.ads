package Editor.Line_Numbers is

   type Line_Number_Mode is
     (Absolute_Line_Numbers,
      Relative_Line_Numbers,
      Hybrid_Line_Numbers);

   type Line_Number_Config is record
      Mode : Line_Number_Mode := Absolute_Line_Numbers;
   end record;

   --  Return the active process-wide line-number configuration.
   --  @return current line-number configuration
   function Current return Line_Number_Config;

   --  Replace the active process-wide line-number configuration.
   --  @param Config configuration to make active
   procedure Set_Current (Config : Line_Number_Config);

   --  Restore the default absolute line-number configuration.
   procedure Reset;

   --  Return the stable persisted name for Mode.
   function Line_Number_Mode_Name (Mode : Line_Number_Mode) return String;

   --  Parse a stable persisted line-number mode name.
   function Line_Number_Mode_From_Name
     (Name  : String;
      Found : out Boolean) return Line_Number_Mode;

   --  Cycle the active mode deterministically: absolute, relative, hybrid.
   procedure Toggle_Mode;

   --  Format the gutter text for a logical document row.
   --  Values are based on document rows, not visible rows.  Absolute and
   --  hybrid-current values are one-based; relative values are zero-based
   --  distances from Current_Row.
   --  @param Config line-number configuration to apply
   --  @param Document_Row zero-based logical document row being rendered
   --  @param Current_Row zero-based primary-caret logical document row
   --  @return display text for the gutter line number
   function Display_Text
     (Config       : Line_Number_Config;
      Document_Row : Natural;
      Current_Row  : Natural) return String;

end Editor.Line_Numbers;
