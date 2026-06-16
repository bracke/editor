with Ada.Characters.Handling;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Editor.Ada_Implicit_Conversions;
with Editor.Ada_Subtype_Compatibility;
with Editor.Ada_Type_Graph;

package body Editor.Ada_Expected_Call_Filters is

   pragma Suppress (Overflow_Check);

   use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Id;
   use type Editor.Ada_Call_Profile_Filters.Profile_Filter_Status;
   use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id;
   use type Editor.Ada_Call_Profile_Shapes.Callable_Profile_Status;
   use type Editor.Ada_Call_Resolution.Call_Resolution_Id;
   use type Editor.Ada_Call_Resolution.Call_Resolution_Status;
   use type Editor.Ada_Direct_Visibility.Declaration_Id;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Id;
   use type Editor.Ada_Expected_Type_Contexts.Expected_Context_Status;
   use type Editor.Ada_Syntax_Tree.Node_Id;
   use type Editor.Ada_Type_Graph.Type_Id;
   use type Editor.Ada_Subtype_Compatibility.Compatibility_Status;
   use type Editor.Ada_Type_Graph.Compatibility_Status;

   function To_String
     (Value : Ada.Strings.Unbounded.Unbounded_String) return String
      renames Ada.Strings.Unbounded.To_String;

   function To_Unbounded_String (Value : String)
      return Ada.Strings.Unbounded.Unbounded_String
      renames Ada.Strings.Unbounded.To_Unbounded_String;

   function Normalize (Text : String) return String is
   begin
      return Ada.Characters.Handling.To_Lower
        (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));
   end Normalize;



   function Ends_With (Text : String; Suffix : String) return Boolean is
      T : constant String := Normalize (Text);
      S : constant String := Normalize (Suffix);
   begin
      return T'Length >= S'Length
        and then T (T'Last - S'Length + 1 .. T'Last) = S;
   end Ends_With;

   function Class_Wide_Root_Name (Text : String) return String is
      T : constant String := Normalize (Text);
   begin
      if Ends_With (T, "'class") then
         if T'Length <= 6 then
            return "";
         end if;
         return T (T'First .. T'Last - 6);
      else
         return T;
      end if;
   end Class_Wide_Root_Name;

   function Hash_Text (Text : String) return Natural is
      Result : Natural := 0;
   begin
      for C of Text loop
         Result :=
           (Result * 131 + Character'Pos (Ada.Characters.Handling.To_Lower (C)) + 1)
           mod Natural'Last;
      end loop;
      return Result;
   end Hash_Text;

   procedure Mix (Model : in out Expected_Call_Filter_Model; Value : Natural) is
   begin
      Model.Result_Fingerprint :=
        (Model.Result_Fingerprint * 65599 + Value + 241) mod Natural'Last;
   end Mix;

   function Empty_Filter return Expected_Call_Filter_Info is
   begin
      return (Id => No_Expected_Call_Filter,
              Call_Node => Editor.Ada_Syntax_Tree.No_Node,
              Context => Editor.Ada_Expected_Type_Contexts.No_Expected_Context,
              Resolution => Editor.Ada_Call_Resolution.No_Call_Resolution,
              Profile_Filter => Editor.Ada_Call_Profile_Filters.No_Profile_Filter,
              Callable_Profile => Editor.Ada_Call_Profile_Shapes.No_Callable_Profile,
              Declaration => Editor.Ada_Direct_Visibility.No_Declaration,
              Expected_Subtype => Ada.Strings.Unbounded.Null_Unbounded_String,
              Result_Subtype => Ada.Strings.Unbounded.Null_Unbounded_String,
              Normalized_Expected => Ada.Strings.Unbounded.Null_Unbounded_String,
              Normalized_Result => Ada.Strings.Unbounded.Null_Unbounded_String,
              Status => Expected_Call_Filter_Not_Checked,
              Compatibility => Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Not_Checked,
              Type_Compatibility => Editor.Ada_Type_Graph.Type_Compatibility_Not_Checked,
              Implicit_Conversion => Editor.Ada_Implicit_Conversions.Implicit_Conversion_Not_Checked,
              Start_Line => 1,
              End_Line => 1,
              Fingerprint => 0);
   end Empty_Filter;

   function Is_Profile_Compatible
     (Status : Editor.Ada_Call_Profile_Filters.Profile_Filter_Status) return Boolean is
   begin
      return Status = Editor.Ada_Call_Profile_Filters.Profile_Filter_Arity_Compatible
        or else Status = Editor.Ada_Call_Profile_Filters.Profile_Filter_Formal_Name_Compatible;
   end Is_Profile_Compatible;

   function First_Compatible_Filter_For_Node
     (Filters : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model;
      Node    : Editor.Ada_Syntax_Tree.Node_Id)
      return Editor.Ada_Call_Profile_Filters.Profile_Filter_Info
   is
      Info : Editor.Ada_Call_Profile_Filters.Profile_Filter_Info;
   begin
      for Index in 1 .. Editor.Ada_Call_Profile_Filters.Profile_Filter_Count (Filters) loop
         Info := Editor.Ada_Call_Profile_Filters.Profile_Filter_At (Filters, Index);
         if Info.Call_Node = Node and then Is_Profile_Compatible (Info.Status) then
            return Info;
         end if;
      end loop;
      return Editor.Ada_Call_Profile_Filters.Profile_Filter
        (Filters, Editor.Ada_Call_Profile_Filters.No_Profile_Filter);
   end First_Compatible_Filter_For_Node;

   function Callable_Profile_By_Id
     (Shapes : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Id     : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Id)
      return Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info is
   begin
      return Editor.Ada_Call_Profile_Shapes.Callable_Profile (Shapes, Id);
   end Callable_Profile_By_Id;

   procedure Add_Filter
     (Model       : in out Expected_Call_Filter_Model;
      Context     : Editor.Ada_Expected_Type_Contexts.Expected_Context_Info;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Filters     : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model;
      Shapes      : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Types       : Editor.Ada_Type_Graph.Type_Model;
      Use_Types   : Boolean)
   is
      Id : constant Expected_Call_Filter_Id :=
        Expected_Call_Filter_Id (Natural (Model.Filters.Length) + 1);
      Info : Expected_Call_Filter_Info := Empty_Filter;
      Resolution : constant Editor.Ada_Call_Resolution.Call_Resolution_Info :=
        Editor.Ada_Call_Resolution.Call_Resolution (Resolutions, Context.Resolution);
      Profile_Filter : Editor.Ada_Call_Profile_Filters.Profile_Filter_Info;
      Callable : Editor.Ada_Call_Profile_Shapes.Callable_Profile_Info;
      Expected : constant String := To_String (Context.Normalized_Subtype);
   begin
      Info.Id := Id;
      Info.Call_Node := Context.Node;
      Info.Context := Context.Id;
      Info.Resolution := Context.Resolution;
      Info.Expected_Subtype := Context.Expected_Subtype;
      Info.Normalized_Expected := Context.Normalized_Subtype;
      Info.Start_Line := Context.Start_Line;
      Info.End_Line := Context.End_Line;

      if Context.Id = Editor.Ada_Expected_Type_Contexts.No_Expected_Context then
         Info.Status := Expected_Call_Filter_No_Expected_Context;
      elsif Context.Status /= Editor.Ada_Expected_Type_Contexts.Expected_Context_Found then
         Info.Status := Expected_Call_Filter_Context_Not_Found;
      elsif Context.Resolution = Editor.Ada_Call_Resolution.No_Call_Resolution then
         Info.Status := Expected_Call_Filter_No_Call_Resolution;
      elsif Resolution.Status /= Editor.Ada_Call_Resolution.Call_Resolution_Unique_Profile_Match then
         Info.Status := Expected_Call_Filter_No_Unique_Profile;
      else
         Profile_Filter := First_Compatible_Filter_For_Node (Filters, Context.Node);
         Info.Profile_Filter := Profile_Filter.Id;
         Info.Declaration := Profile_Filter.Declaration;
         if Profile_Filter.Id = Editor.Ada_Call_Profile_Filters.No_Profile_Filter then
            Info.Status := Expected_Call_Filter_No_Profile_Filter;
         else
            Callable := Callable_Profile_By_Id (Shapes, Profile_Filter.Callable_Profile);
            Info.Callable_Profile := Callable.Id;
            if Callable.Id = Editor.Ada_Call_Profile_Shapes.No_Callable_Profile
              or else Callable.Status /= Editor.Ada_Call_Profile_Shapes.Callable_Profile_Found
            then
               Info.Status := Expected_Call_Filter_No_Callable_Profile;
            elsif not Callable.Has_Result then
               Info.Status := Expected_Call_Filter_Callable_Has_No_Result;
            else
               declare
                  Result : constant String :=
                    Normalize (To_String (Callable.Result_Subtype));
               begin
                  Info.Result_Subtype := Callable.Result_Subtype;
                  Info.Normalized_Result := To_Unbounded_String (Result);
                  declare
                     Expected_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                       (if Use_Types then
                           Editor.Ada_Type_Graph.Lookup_Type
                             (Types, Context.Region,
                              (if Ends_With (Expected, "'class") then Class_Wide_Root_Name (Expected) else Expected))
                        else
                           Editor.Ada_Type_Graph.No_Type);
                     Result_Type : constant Editor.Ada_Type_Graph.Type_Id :=
                       (if Use_Types then
                           Editor.Ada_Type_Graph.Lookup_Type
                             (Types, Callable.Region,
                              (if Ends_With (Result, "'class") then Class_Wide_Root_Name (Result) else Result))
                        else
                           Editor.Ada_Type_Graph.No_Type);
                     Graph_Status : constant Editor.Ada_Type_Graph.Compatibility_Status :=
                       (if Use_Types
                          and then Expected_Type /= Editor.Ada_Type_Graph.No_Type
                          and then Result_Type /= Editor.Ada_Type_Graph.No_Type
                        then
                           (if Ends_With (Expected, "'class") then
                              Editor.Ada_Type_Graph.Class_Wide_Compatibility
                                (Types, Expected_Type, Result_Type)
                            else
                              Editor.Ada_Type_Graph.Compatibility
                                (Types, Expected_Type, Result_Type))
                        else
                           Editor.Ada_Type_Graph.Type_Compatibility_Not_Checked);
                     Compatibility : constant Editor.Ada_Subtype_Compatibility.Compatibility_Info :=
                       (if Use_Types then
                           Editor.Ada_Subtype_Compatibility.Check_With_Type_Graph
                             (Types, Context.Region, Callable.Region, Expected, Result)
                        else
                           Editor.Ada_Subtype_Compatibility.Check (Expected, Result));
                     Implicit : constant Editor.Ada_Implicit_Conversions.Implicit_Conversion_Info :=
                       Editor.Ada_Implicit_Conversions.Classify (Compatibility);
                  begin
                     Info.Compatibility := Compatibility.Status;
                     Info.Type_Compatibility := Graph_Status;
                     Info.Implicit_Conversion := Implicit.Status;
                     if Expected /= "" and then Result = Expected then
                        Info.Status := Expected_Call_Filter_Result_Subtype_Matches;
                     elsif Editor.Ada_Subtype_Compatibility.Is_Compatible (Compatibility) then
                        Info.Status := Expected_Call_Filter_Result_Subtype_Compatible;
                     elsif Compatibility.Status =
                       Editor.Ada_Subtype_Compatibility.Subtype_Compatibility_Indeterminate
                     then
                        Info.Status := Expected_Call_Filter_Result_Subtype_Indeterminate;
                     else
                        Info.Status := Expected_Call_Filter_Result_Subtype_Mismatch;
                     end if;
                  end;
               end;
            end if;
         end if;
      end if;

      Info.Fingerprint :=
        (Expected_Call_Filter_Status'Pos (Info.Status) * 1000003
         + Natural (Info.Call_Node) * 1009
         + Natural (Info.Context) * 503
         + Natural (Info.Resolution) * 211
         + Natural (Info.Profile_Filter) * 97
         + Natural (Info.Callable_Profile) * 53
         + Natural (Info.Declaration) * 31
         + Editor.Ada_Subtype_Compatibility.Compatibility_Status'Pos (Info.Compatibility) * 19
         + Editor.Ada_Type_Graph.Compatibility_Status'Pos (Info.Type_Compatibility) * 23
         + Editor.Ada_Implicit_Conversions.Implicit_Conversion_Status'Pos (Info.Implicit_Conversion) * 29
         + Hash_Text (To_String (Info.Normalized_Expected)) * 17
         + Hash_Text (To_String (Info.Normalized_Result)) * 13) mod Natural'Last;
      Model.Filters.Append (Info);
      Mix (Model, Info.Fingerprint);
   end Add_Filter;

   procedure Clear (Model : in out Expected_Call_Filter_Model) is
   begin
      Model.Filters.Clear;
      Model.Result_Fingerprint := 0;
   end Clear;

   function Build
     (Contexts   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Filters    : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model;
      Shapes     : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model)
      return Expected_Call_Filter_Model
   is
      Model : Expected_Call_Filter_Model;
      Empty_Types : Editor.Ada_Type_Graph.Type_Model;
   begin
      Clear (Model);
      Editor.Ada_Type_Graph.Clear (Empty_Types);
      for Index in 1 .. Editor.Ada_Expected_Type_Contexts.Expected_Context_Count (Contexts) loop
         Add_Filter
           (Model,
            Editor.Ada_Expected_Type_Contexts.Expected_Context_At (Contexts, Index),
            Resolutions,
            Filters,
            Shapes,
            Empty_Types,
            False);
      end loop;
      Mix (Model, Editor.Ada_Expected_Type_Contexts.Fingerprint (Contexts));
      Mix (Model, Editor.Ada_Call_Resolution.Fingerprint (Resolutions));
      Mix (Model, Editor.Ada_Call_Profile_Filters.Fingerprint (Filters));
      Mix (Model, Editor.Ada_Call_Profile_Shapes.Fingerprint (Shapes));
      return Model;
   end Build;

   function Build_With_Type_Graph
     (Contexts   : Editor.Ada_Expected_Type_Contexts.Expected_Context_Model;
      Resolutions : Editor.Ada_Call_Resolution.Call_Resolution_Model;
      Filters    : Editor.Ada_Call_Profile_Filters.Profile_Filter_Model;
      Shapes     : Editor.Ada_Call_Profile_Shapes.Profile_Shape_Model;
      Types      : Editor.Ada_Type_Graph.Type_Model)
      return Expected_Call_Filter_Model
   is
      Model : Expected_Call_Filter_Model;
   begin
      Clear (Model);
      for Index in 1 .. Editor.Ada_Expected_Type_Contexts.Expected_Context_Count (Contexts) loop
         Add_Filter
           (Model,
            Editor.Ada_Expected_Type_Contexts.Expected_Context_At (Contexts, Index),
            Resolutions,
            Filters,
            Shapes,
            Types,
            True);
      end loop;
      Mix (Model, Editor.Ada_Expected_Type_Contexts.Fingerprint (Contexts));
      Mix (Model, Editor.Ada_Call_Resolution.Fingerprint (Resolutions));
      Mix (Model, Editor.Ada_Call_Profile_Filters.Fingerprint (Filters));
      Mix (Model, Editor.Ada_Call_Profile_Shapes.Fingerprint (Shapes));
      Mix (Model, Editor.Ada_Type_Graph.Fingerprint (Types));
      return Model;
   end Build_With_Type_Graph;

   function Has_Expected_Call_Filters
     (Model : Expected_Call_Filter_Model) return Boolean is
   begin
      return not Model.Filters.Is_Empty;
   end Has_Expected_Call_Filters;

   function Expected_Call_Filter_Count
     (Model : Expected_Call_Filter_Model) return Natural is
   begin
      return Natural (Model.Filters.Length);
   end Expected_Call_Filter_Count;

   function Expected_Call_Filter_At
     (Model : Expected_Call_Filter_Model;
      Index : Positive) return Expected_Call_Filter_Info is
   begin
      if Index > Natural (Model.Filters.Length) then
         return Empty_Filter;
      end if;
      return Model.Filters (Index);
   end Expected_Call_Filter_At;

   function Expected_Call_Filter
     (Model : Expected_Call_Filter_Model;
      Id    : Expected_Call_Filter_Id) return Expected_Call_Filter_Info is
   begin
      if Id = No_Expected_Call_Filter
        or else Natural (Id) > Natural (Model.Filters.Length)
      then
         return Empty_Filter;
      end if;
      return Model.Filters (Positive (Id));
   end Expected_Call_Filter;

   function Expected_Call_Filter_For_Node
     (Model : Expected_Call_Filter_Model;
      Node  : Editor.Ada_Syntax_Tree.Node_Id) return Expected_Call_Filter_Info is
   begin
      for Info of Model.Filters loop
         if Info.Call_Node = Node then
            return Info;
         end if;
      end loop;
      return Empty_Filter;
   end Expected_Call_Filter_For_Node;

   function Count_Status
     (Model  : Expected_Call_Filter_Model;
      Status : Expected_Call_Filter_Status) return Natural
   is
      Count : Natural := 0;
   begin
      for Info of Model.Filters loop
         if Info.Status = Status then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Count_Status;

   function Fingerprint (Model : Expected_Call_Filter_Model) return Natural is
   begin
      return Model.Result_Fingerprint;
   end Fingerprint;

end Editor.Ada_Expected_Call_Filters;
