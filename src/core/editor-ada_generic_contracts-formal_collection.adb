separate (Editor.Ada_Generic_Contracts)
package body Formal_Collection is

   procedure Add_Formal
     (Model : in out Generic_Contract_Model;
      Tree  : Editor.Ada_Syntax_Tree.Tree_Type;
      Decl  : Editor.Ada_Direct_Visibility.Declaration_Info)
   is
      Id      : constant Generic_Formal_Id :=
        Generic_Formal_Id (Natural (Model.Formals.Length) + 1);
      Node    : constant Editor.Ada_Syntax_Tree.Node_Info :=
        Editor.Ada_Syntax_Tree.Node (Tree, Decl.Node);
      Label   : constant String := Trim (To_String (Node.Label));
      Default : constant String :=
        Trim (Child_Label (Tree, Node.Id, Editor.Ada_Syntax_Tree.Node_Declaration_Default));
      Effective_Default : constant String :=
        (if Default /= "" then Default else Default_Text_From_Label (Label));
      Info    : Generic_Formal_Info := Empty_Formal;
      Kind    : constant Generic_Formal_Kind := To_Formal_Kind (Decl.Kind);
      Name    : constant String := Trim (To_String (Decl.Name));
      Param_Count : Natural := 0;
      Param_Subtypes : Unbounded_String;
      Param_Modes : Unbounded_String;
      Param_Names : Unbounded_String;
      Param_Defaults : Unbounded_String;
      Has_Result  : Boolean := False;
      Result_Subtype : Unbounded_String;
      Profile_Malformed : Boolean := False;
      Package_Target : constant String := Generic_Name_From_Label (Label);
   begin
      Info.Id := Id;
      Info.Declaration := Decl.Id;
      Info.Node := Decl.Node;
      Info.Region := Decl.Region;
      Info.Name := To_Unbounded_String (Name);
      Info.Normalized_Name := To_Unbounded_String (Normalize (Name));
      Info.Kind := Kind;
      Info.Has_Default := Default /= "" or else Contains (Label, ":=")
        or else Contains (Ada.Characters.Handling.To_Lower (Label), " is <>")
        or else Contains (Ada.Characters.Handling.To_Lower (Label), " is null")
        or else Contains (Ada.Characters.Handling.To_Lower (Label), " is abstract")
        or else (Kind = Generic_Formal_Package and then Formal_Package_Has_Box_Actuals (Label));
      Info.Default_Text :=
        To_Unbounded_String
          (if Effective_Default /= "" then Effective_Default
           elsif Kind = Generic_Formal_Package and then Formal_Package_Has_Box_Actuals (Label) then "<>"
           else "");
      if Kind = Generic_Formal_Subprogram then
         Analyze_Subprogram_Profile
           (Tree, Node.Id, Param_Count, Param_Subtypes, Param_Modes, Param_Names, Param_Defaults, Has_Result,
            Result_Subtype, Profile_Malformed);
         Info.Formal_Parameter_Count := Param_Count;
         Info.Formal_Parameter_Subtypes := Param_Subtypes;
         Info.Formal_Parameter_Modes := Param_Modes;
         Info.Formal_Parameter_Names := Param_Names;
         Info.Formal_Parameter_Defaults := Param_Defaults;
         Info.Formal_Subprogram_Convention :=
           To_Unbounded_String (Convention_For_Declaration (Tree, Node.Id));
         if Has_Result = False then
            declare
               Label_Result : constant String := Result_Subtype_From_Label (Label);
            begin
               if Label_Result /= "" then
                  Has_Result := True;
                  Result_Subtype := To_Unbounded_String (Label_Result);
               end if;
            end;
         end if;
         Info.Formal_Has_Result := Has_Result;
         Info.Formal_Result_Subtype := Result_Subtype;
      elsif Kind = Generic_Formal_Package then
         Info.Formal_Package_Generic_Name := To_Unbounded_String (Package_Target);
         Info.Formal_Package_Normalized_Generic :=
           To_Unbounded_String (Normalize (Package_Target));
         Info.Formal_Package_Has_Box := Formal_Package_Has_Box_Actuals (Label);
      end if;
      Info.Status := (if Name = "" then Generic_Formal_Missing_Name else Generic_Formal_Record_Valid);
      Info.Start_Line := Decl.Start_Line;
      Info.End_Line := Decl.End_Line;
      Info.Fingerprint :=
        (Natural (Id) * 1000003
         + Natural (Decl.Id) * 1009
         + Natural (Decl.Region) * 97
         + Generic_Formal_Kind'Pos (Kind) * 31
         + Param_Count * 29
         + (if Has_Result then 23 else 0)
         + (if Info.Has_Default then 17 else 0)
         + Hash_Text (Name)
         + Hash_Text (Label)
         + Hash_Text (Effective_Default)
         + Hash_Text (To_String (Param_Subtypes))
         + Hash_Text (To_String (Param_Defaults))
         + Hash_Text (To_String (Param_Modes))
         + Hash_Text (To_String (Param_Names))
         + Hash_Text (To_String (Info.Formal_Subprogram_Convention))
         + Hash_Text (To_String (Result_Subtype))
         + Hash_Text (Package_Target)
         + (if Info.Formal_Package_Has_Box then 41 else 0)) mod Natural'Last;
      Model.Formals.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Formal;


end Formal_Collection;
