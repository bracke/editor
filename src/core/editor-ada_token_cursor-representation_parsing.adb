with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with Editor.Ada_Token_Cursor.Aggregate_Parsing;
with Editor.Ada_Token_Cursor.Contracts;
with Editor.Ada_Token_Cursor.Expression_Parsing;
with Editor.Ada_Token_Cursor.Grammar_Helpers;
with Editor.Ada_Token_Cursor.Tokenization;
with Editor.Ada_Token_Cursor.Navigation_Helpers;
with Editor.Ada_Token_Cursor.Selected_Name_Parsing;
with Editor.Ada_Token_Cursor.Range_Structure_Helpers;
with Editor.Ada_Token_Cursor; use Editor.Ada_Token_Cursor;

package body Editor.Ada_Token_Cursor.Representation_Parsing is

   use Editor.Ada_Token_Cursor.Tokenization;
   use Editor.Ada_Token_Cursor.Grammar_Helpers;
   use Editor.Ada_Token_Cursor.Navigation_Helpers;
   use Editor.Ada_Token_Cursor.Expression_Parsing;
   use Editor.Ada_Token_Cursor.Aggregate_Parsing;
   use Editor.Ada_Token_Cursor.Selected_Name_Parsing;
   use Editor.Ada_Token_Cursor.Range_Structure_Helpers;

   procedure Add_Production
     (Result : in out Grammar_Result;
      Kind   : Production_Kind;
      Tok    : Token_Info;
      Label  : String)
     renames Editor.Ada_Token_Cursor.Grammar_Helpers.Add_Production;

   procedure Parse_Representation_Target
     (Position : in out Cursor;
      Result   : in out Grammar_Result;
      Stop     : String) is
      Tok : constant Token_Info := Current (Position);

      function At_Representation_Target_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
         S : constant String := To_String (Current (Position).Text);
      begin
         return S = ")"
           or else L = "private"
           or else L = "begin"
           or else L = "end"
           or else L = "with"
           or else L = "package"
           or else L = "procedure"
           or else L = "function"
           or else L = "type"
           or else L = "subtype"
           or else L = "task"
           or else L = "protected";
      end At_Representation_Target_Boundary;
   begin
      Add_Production
        (Result, Production_Representation_Target, Tok, To_String (Tok.Text));

      while not At_End (Position)
        and then To_String (Current (Position).Text) /= Stop
        and then Current_Lower (Position) /= "use"
        and then To_String (Current (Position).Text) /= ";"
      loop
         if At_Representation_Target_Boundary then
            Add_Production
              (Result,
               Production_Representation_Target_Reserved_Boundary_Recovery_Boundary,
               Current (Position),
               "representation target stopped at declaration boundary");
            Add_Production
              (Result, Production_Recovery_Point, Current (Position),
               "expected use or attribute designator after representation target");
            exit;
         end if;

         declare
            T : constant Token_Info := Current (Position);
            S : constant String := To_String (T.Text);
         begin
            if T.Kind = Token_Identifier or else T.Kind = Token_Keyword then
               Add_Production (Result, Production_Name, T, S);
               Advance (Position);
            elsif S = "." then
               Parse_Selected_Name_Suffix
                 (Position, Result, Tok, "representation target");
            elsif S = "(" then
               Add_Production
                 (Result, Production_Call_Or_Indexed_Component, Tok,
                  "call or indexed component suffix");
               Add_Production
                 (Result, Production_Indexed_Component, Tok, To_String (Tok.Text));
               Parse_Association_List (Position, Result);
            else
               Advance (Position);
            end if;
         end;
      end loop;
   end Parse_Representation_Target;

   procedure Parse_Attribute_Designator
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Attribute_Designator, Tok, To_String (Tok.Text));
      Add_Production
        (Result, Production_Attribute_Designator_Name, Tok, To_String (Tok.Text));

      if Current (Position).Kind = Token_String_Literal
        or else Current (Position).Kind = Token_Operator
        or else Current (Position).Kind = Token_Identifier
        or else Current (Position).Kind = Token_Keyword
      then
         Advance (Position);
      else
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected attribute designator in representation clause");
      end if;
   end Parse_Attribute_Designator;

   function Is_Stream_Attribute_Designator (Lower_Name : String) return Boolean is
   begin
      return Lower_Name = "read"
        or else Lower_Name = "write"
        or else Lower_Name = "input"
        or else Lower_Name = "output";
   end Is_Stream_Attribute_Designator;

   procedure Parse_Record_Representation_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok : constant Token_Info := Current (Position);
   begin
      Add_Production
        (Result, Production_Record_Representation_Clause, Tok,
         "record representation clause");
      while not At_End (Position) loop
         if Current_Lower (Position) = "record" then
            Add_Production
              (Result, Production_Record_Representation_List_Open_Delimiter,
               Current (Position), "record representation list open delimiter");
            Advance (Position);
            exit;
         end if;
         Advance (Position);
      end loop;
      while not At_End (Position) loop
         declare
            L : constant String := Current_Lower (Position);
            T : constant String := To_String (Current (Position).Text);
            C : constant Token_Info := Current (Position);
         begin
            exit when L = "end";
            if L = "at" and then Lookahead_Lower (Position, 1) = "mod" then
               Add_Production
                 (Result, Production_Mod_Clause, C,
                  "record representation mod clause");
               Advance (Position);
               if Match_Keyword (Position, "mod") then
                  Parse_Expression (Position, Result);
               else
                  Add_Production
                    (Result, Production_Recovery_Point, C,
                     "expected mod in record representation clause");
               end if;
               Skip_Balanced_To_Semicolon (Position);
               Add_Production
                 (Result, Production_Record_Representation_Component_Separator,
                  C, "record representation mod clause separator");
            elsif Current (Position).Kind = Token_Identifier
              and then
                (Has_Token_Before_Semicolon (Position, "at")
                 or else Has_Token_Before_Semicolon (Position, "range"))
            then
               Add_Production
                 (Result, Production_Representation_Component_Clause, C,
                  To_String (C.Text));
               Add_Production
                 (Result, Production_Representation_Target, C,
                  To_String (C.Text));
               Advance (Position);
               if Match_Keyword (Position, "at") then
                  Add_Production
                    (Result, Production_Representation_Component_Position,
                     Current (Position), "component position");
                  Parse_Expression (Position, Result);
               else
                  Add_Production
                    (Result,
                     Production_Representation_Component_Missing_At_Recovery_Boundary,
                     C, "expected at in record representation component clause");
                  Add_Production
                    (Result, Production_Recovery_Point, C,
                     "expected at in record representation component clause");
               end if;
               if Match_Keyword (Position, "range") then
                  Add_Production
                    (Result, Production_Representation_Component_First_Bit,
                     Current (Position), "first bit");
                  Parse_Expression (Position, Result);
                  if Match_Symbol (Position, "..") then
                     Add_Production
                       (Result, Production_Representation_Component_Last_Bit,
                        Current (Position), "last bit");
                     Parse_Expression (Position, Result);
                  else
                     Add_Production
                       (Result, Production_Recovery_Point, C,
                        "expected .. in record representation component range");
                  end if;
               else
                  Add_Production
                    (Result,
                     Production_Representation_Component_Missing_Range_Recovery_Boundary,
                     C, "expected range in record representation component clause");
                  Add_Production
                    (Result, Production_Recovery_Point, C,
                     "expected range in record representation component clause");
               end if;
               Skip_Balanced_To_Semicolon (Position);
               Add_Production
                 (Result, Production_Record_Representation_Component_Separator,
                  C, "record representation component separator");
            elsif T = ";" then
               Advance (Position);
            else
               Advance (Position);
            end if;
         end;
      end loop;
      if Match_Keyword (Position, "end") then
         if Current_Lower (Position) = "record" then
            Add_Production
              (Result, Production_Record_Representation_List_Close_Delimiter,
               Current (Position), "record representation list close delimiter");
            Advance (Position);
         else
            Add_Production
              (Result,
               Production_Record_Representation_Missing_Close_Recovery_Boundary,
               Tok, "expected record after end in record representation clause");
            Add_Production
              (Result,
               Production_Record_Representation_Missing_End_Record_Recovery_Boundary,
               Tok, "expected record after end in record representation clause");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected record after end in record representation clause");
         end if;
      else
         Add_Production
           (Result,
            Production_Record_Representation_Missing_Close_Recovery_Boundary,
            Tok, "expected end record in record representation clause");
         Add_Production
           (Result,
            Production_Record_Representation_Missing_End_Record_Recovery_Boundary,
            Tok, "expected end record in record representation clause");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected end record in record representation clause");
      end if;
      if To_String (Current (Position).Text) = ";" then
         Advance (Position);
      end if;
   end Parse_Record_Representation_Clause;

   procedure Parse_Representation_Clause
     (Position : in out Cursor;
      Result   : in out Grammar_Result) is
      Tok                 : constant Token_Info := Current (Position);
      Start_Mark          : constant Natural := Mark (Position);
      Is_Attribute_Clause : Boolean := False;
      Is_Address_Attribute : Boolean := False;
      Attribute_Name      : Unbounded_String;

      function At_Representation_Item_Boundary return Boolean is
         L : constant String := Current_Lower (Position);
         S : constant String := To_String (Current (Position).Text);
      begin
         return At_End (Position)
           or else S = ";"
           or else S = ")"
           or else L = "private"
           or else L = "begin"
           or else L = "end"
           or else L = "with"
           or else L = "package"
           or else L = "procedure"
           or else L = "function"
           or else L = "type"
           or else L = "subtype"
           or else L = "task"
           or else L = "protected";
      end At_Representation_Item_Boundary;

      function Has_Apostrophe_Before_Use return Boolean is
         Probe       : Cursor := Position;
         Paren_Depth : Natural := 0;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
               L : constant String := Current_Lower (Probe);
            begin
               if T = "(" then
                  Paren_Depth := Paren_Depth + 1;
               elsif T = ")" and then Paren_Depth > 0 then
                  Paren_Depth := Paren_Depth - 1;
               elsif L = "use" and then Paren_Depth = 0 then
                  return False;
               elsif T = ";" and then Paren_Depth = 0 then
                  return False;
               elsif T = "'" and then Paren_Depth = 0 then
                  return True;
               end if;
               Advance (Probe);
            end;
         end loop;
         return False;
      end Has_Apostrophe_Before_Use;

      function Has_Arrow_Before_Enumeration_Association_End return Boolean is
         Probe : Cursor := Position;
         Depth : Natural := 0;
      begin
         while not At_End (Probe) loop
            declare
               T : constant String := To_String (Current (Probe).Text);
            begin
               if T = "(" or else T = "[" then
                  Depth := Depth + 1;
               elsif T = ")" then
                  if Depth = 0 then
                     return False;
                  else
                     Depth := Depth - 1;
                  end if;
               elsif T = "]" then
                  if Depth > 0 then
                     Depth := Depth - 1;
                  end if;
               elsif Depth = 0 and then (T = "," or else T = ";") then
                  return False;
               elsif Depth = 0 and then T = "=>" then
                  return True;
               end if;
               Advance (Probe);
            end;
         end loop;
         return False;
      end Has_Arrow_Before_Enumeration_Association_End;
   begin
      Add_Production (Result, Production_Representation_Clause, Tok,
                      "representation clause");
      if not Match_Keyword (Position, "for") then
         return;
      end if;
      Is_Attribute_Clause := Has_Apostrophe_Before_Use;

      Parse_Representation_Target (Position, Result, "'");

      if Is_Attribute_Clause then
         Add_Production
           (Result, Production_Attribute_Definition_Clause, Tok,
            "attribute definition clause");
         Add_Production
           (Result, Production_Operational_Item, Tok,
            "operational item");
         Add_Production
           (Result, Production_Operational_Attribute_Definition_Clause, Tok,
            "operational attribute definition clause");
         if Match_Symbol (Position, "'") then
            if Current_Lower (Position) = "class"
              and then Lookahead_Lower (Position, 1) = "'"
            then
               Add_Production
                 (Result, Production_Classwide_Attribute_Prefix,
                  Current (Position), "class-wide attribute prefix");
               Parse_Attribute_Designator (Position, Result);
               if not Match_Symbol (Position, "'") then
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected attribute designator after class-wide prefix");
               end if;
            end if;

            if Current_Lower (Position) = "use"
              or else At_Representation_Item_Boundary
            then
               Add_Production
                 (Result,
                  Production_Attribute_Definition_Missing_Designator_Recovery_Boundary,
                  Tok, "missing attribute designator in attribute definition clause");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected attribute designator in attribute definition clause");
            end if;

            Attribute_Name := To_Unbounded_String (Current_Lower (Position));
            Is_Address_Attribute := To_String (Attribute_Name) = "address";
            if Is_Address_Attribute then
               Add_Production
                 (Result, Production_Address_Clause, Tok,
                  "address attribute definition clause");
            end if;
            if Is_Stream_Attribute_Designator (To_String (Attribute_Name)) then
               Add_Production
                 (Result, Production_Stream_Attribute_Definition_Clause, Tok,
                  "stream attribute definition clause");
            end if;
            if To_String (Attribute_Name) = "size"
              or else To_String (Attribute_Name) = "object_size"
              or else To_String (Attribute_Name) = "value_size"
              or else To_String (Attribute_Name) = "component_size"
            then
               Add_Production
                 (Result, Production_Size_Attribute_Definition_Clause, Tok,
                  "size attribute definition clause");
            elsif To_String (Attribute_Name) = "alignment" then
               Add_Production
                 (Result, Production_Alignment_Attribute_Definition_Clause, Tok,
                  "alignment attribute definition clause");
            elsif To_String (Attribute_Name) = "external_tag" then
               Add_Production
                 (Result, Production_External_Tag_Attribute_Definition_Clause, Tok,
                  "external tag attribute definition clause");
            elsif To_String (Attribute_Name) = "storage_size"
              or else To_String (Attribute_Name) = "storage_pool"
              or else To_String (Attribute_Name) = "storage_unit"
              or else To_String (Attribute_Name) = "scalar_storage_order"
            then
               Add_Production
                 (Result, Production_Storage_Attribute_Definition_Clause, Tok,
                  "storage attribute definition clause");
            end if;
            if not (Current_Lower (Position) = "use"
                    or else At_Representation_Item_Boundary)
            then
               Parse_Attribute_Designator (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected attribute designator in attribute definition clause");
         end if;
         if Match_Keyword (Position, "use") then
            if At_Representation_Item_Boundary
            then
               if Is_Address_Attribute then
                  Add_Production
                    (Result, Production_Address_Clause_Missing_Value_Recovery_Boundary,
                     Tok, "missing address value expression");
               else
                  Add_Production
                    (Result, Production_Attribute_Definition_Missing_Value_Recovery_Boundary,
                     Tok, "missing attribute definition value expression");
               end if;
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected representation value expression after use");
            else
               if Is_Address_Attribute then
                  Add_Production
                    (Result, Production_Address_Value_Expression,
                     Current (Position), "address value expression");
               else
                  Add_Production
                    (Result, Production_Representation_Value_Expression,
                     Current (Position), "representation value expression");
               end if;
               Parse_Expression (Position, Result);
            end if;
         else
            Add_Production
              (Result, Production_Attribute_Definition_Missing_Use_Recovery_Boundary,
               Tok, "missing use in attribute definition clause");
            Add_Production
              (Result, Production_Recovery_Point, Tok,
               "expected use in attribute definition clause");
         end if;
         Skip_Balanced_To_Semicolon (Position);
      elsif Match_Keyword (Position, "use") then
         if Current_Lower (Position) = "record" then
            Restore (Position, Start_Mark);
            Parse_Record_Representation_Clause (Position, Result);
         elsif Match_Keyword (Position, "at") then
            Add_Production (Result, Production_Address_Clause, Tok,
                            "address clause");
            if At_Representation_Item_Boundary
            then
               Add_Production
                 (Result, Production_Address_Clause_Missing_Value_Recovery_Boundary,
                  Tok, "missing address value expression");
               Add_Production
                 (Result, Production_Recovery_Point, Tok,
                  "expected address value expression after at");
            else
               Add_Production
                 (Result, Production_Address_Value_Expression,
                  Current (Position), "address value expression");
               Parse_Expression (Position, Result);
            end if;
            Skip_Balanced_To_Semicolon (Position);
         elsif To_String (Current (Position).Text) = "(" then
            Add_Production
              (Result, Production_Enumeration_Representation_Clause, Tok,
               "enumeration representation clause");
            if To_String (Current (Position).Text) = "(" then
               Add_Production
                 (Result,
                  Production_Enumeration_Representation_List_Open_Delimiter,
                  Current (Position), "enumeration representation list open delimiter");
            end if;
            if Match_Symbol (Position, "(") then
               if To_String (Current (Position).Text) = ")" then
                  Add_Production
                    (Result,
                     Production_Enumeration_Representation_Empty_List_Recovery_Boundary,
                     Tok, "empty enumeration representation list");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected enumeration representation association");
               end if;

               while not At_End (Position)
                 and then To_String (Current (Position).Text) /= ")"
                 and then To_String (Current (Position).Text) /= ";"
               loop
                  if At_Representation_Item_Boundary then
                     Add_Production
                       (Result,
                        Production_Enumeration_Representation_Reserved_Association_Recovery_Boundary,
                        Current (Position),
                        "enumeration representation association stopped at declaration boundary");
                     Add_Production
                       (Result, Production_Recovery_Point, Current (Position),
                        "expected enumeration representation association");
                     exit;
                  end if;

                  declare
                     Assoc_Tok : constant Token_Info := Current (Position);
                  begin
                     Add_Production
                       (Result, Production_Enumeration_Representation_Association,
                        Assoc_Tok, To_String (Assoc_Tok.Text));
                     if Has_Arrow_Before_Enumeration_Association_End then
                        Add_Production
                          (Result,
                           Production_Enumeration_Representation_Choice_List,
                           Assoc_Tok, "enumeration representation choice list");
                        Parse_Discrete_Choice_List (Position, Result, "=>");
                        if Match_Symbol (Position, "=>") then
                           if To_String (Current (Position).Text) = ","
                             or else To_String (Current (Position).Text) = ")"
                             or else To_String (Current (Position).Text) = ";"
                           then
                              Add_Production
                                (Result,
                                 Production_Enumeration_Representation_Missing_Value_Recovery_Boundary,
                                 Assoc_Tok,
                                 "missing enumeration representation value expression");
                              Add_Production
                                (Result, Production_Recovery_Point, Assoc_Tok,
                                 "expected enumeration representation value expression");
                           else
                              Add_Production
                                (Result, Production_Representation_Value_Expression,
                                 Current (Position), "enumeration representation value expression");
                              Parse_Expression (Position, Result);
                           end if;
                        else
                           Add_Production
                             (Result, Production_Recovery_Point, Assoc_Tok,
                              "expected => in enumeration representation association");
                           Skip_Balanced_To (Position, ",", ")", ";");
                        end if;
                     else
                        Add_Production
                          (Result, Production_Representation_Value_Expression,
                           Current (Position), "enumeration representation value expression");
                        Parse_Expression (Position, Result);
                     end if;
                  end;
                  if To_String (Current (Position).Text) = "," then
                     Add_Production
                       (Result,
                        Production_Enumeration_Representation_Association_Separator,
                        Current (Position),
                        "enumeration representation association separator");
                     Advance (Position);
                     if To_String (Current (Position).Text) = ")"
                       or else To_String (Current (Position).Text) = ";"
                     then
                        Add_Production
                          (Result,
                           Production_Enumeration_Representation_Trailing_Separator_Recovery_Boundary,
                           Tok,
                           "trailing comma in enumeration representation list");
                        Add_Production
                          (Result, Production_Recovery_Point, Tok,
                           "expected enumeration representation association after comma");
                     end if;
                  else
                     exit;
                  end if;
               end loop;
               if To_String (Current (Position).Text) = ")" then
                  Add_Production
                    (Result,
                     Production_Enumeration_Representation_List_Close_Delimiter,
                     Current (Position),
                     "enumeration representation list close delimiter");
                  Advance (Position);
               else
                  Add_Production
                    (Result,
                     Production_Enumeration_Representation_Missing_Close_Recovery_Boundary,
                     Tok, "expected ) in enumeration representation clause");
                  Add_Production
                    (Result, Production_Recovery_Point, Tok,
                     "expected ) in enumeration representation clause");
               end if;
            end if;
            Skip_Balanced_To_Semicolon (Position);
         else
            Add_Production
              (Result, Production_Representation_Value_Expression,
               Current (Position), "representation value expression");
            Parse_Expression (Position, Result);
            Skip_Balanced_To_Semicolon (Position);
         end if;
      else
         Add_Production
           (Result, Production_Representation_Clause_Missing_Use_Recovery_Boundary,
            Tok, "missing use in representation clause");
         Add_Production
           (Result, Production_Recovery_Point, Tok,
            "expected use in representation clause");
         Skip_Balanced_To_Semicolon (Position);
      end if;
   end Parse_Representation_Clause;

end Editor.Ada_Token_Cursor.Representation_Parsing;
