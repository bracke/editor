with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;
with AUnit.Assertions; use AUnit.Assertions;
with AUnit.Test_Cases;
with Editor.Ada_Assignment_Legality;
with Editor.Ada_Control_Flow_Legality;
with Editor.Ada_Conversion_Access_Aggregate_Legality;
with Editor.Ada_Cross_Unit_Semantic_Closure;
with Editor.Ada_Expression_Types;
with Editor.Ada_Generic_Instance_Freezing_Representation_Legality;
with Editor.Ada_Declaration_Parser;
with Editor.Ada_Language_Model;
with Editor.Ada_Language_Service;
with Editor.Ada_Live_Semantic_Diagnostics;
with Editor.Ada_Project_Index;
with Editor.Ada_Return_Legality;
with Editor.Ada_Semantic_Colour_Projection;
with Editor.Ada_Semantic_Diagnostic_Feed;
with Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
with Editor.Ada_Syntax_Tree;
with Editor.Ada_Tagged_Derived_Legality;
with Editor.Ada_Tasking_Protected_Legality;
with Editor.Ada_Wide_Semantic_Legality_Diagnostics;
with Editor.External_Producers;

package body Test_Ada_Language_Service_Integration is

   package LM renames Editor.Ada_Language_Model;
   package LS renames Editor.Ada_Language_Service;
   package PI renames Editor.Ada_Project_Index;
   package EP renames Editor.External_Producers;
   package AL renames Editor.Ada_Assignment_Legality;
   package ET renames Editor.Ada_Expression_Types;
   package SC renames Editor.Ada_Semantic_Colour_Projection;
   package SF renames Editor.Ada_Semantic_Diagnostic_Feed;
   package SG renames Editor.Ada_Semantic_Diagnostic_Snapshot_Guards;
   package WD renames Editor.Ada_Wide_Semantic_Legality_Diagnostics;

   use type LS.Service_Status;
   use type LS.Semantic_Backend_Kind;
   use type LS.Semantic_Diagnostic_Severity;
   use type LS.Semantic_Request_Kind;
   use type LS.Semantic_Request_Status_Kind;
   use type EP.Compiler_Diagnostic_Severity;
   use type SF.Semantic_Diagnostic_Feed_Status;

   overriding function Name (T : Test_Case) return AUnit.Message_String is
      pragma Unreferenced (T);
   begin
      return AUnit.Format ("Test_Ada_Language_Service_Integration");
   end Name;

   procedure Build_Service (Service : in out LS.Service_State) is
      Spec_Analysis : LM.Analysis_Result;
      Body_Analysis : LM.Analysis_Result;
      Flags         : LM.Declaration_Flags := (others => False);
      Ignored       : LM.Symbol_Id;
   begin
      Ignored := LM.Add_Symbol
        (Spec_Analysis, "Demo", LM.Symbol_Package,
         (Start_Line => 1, Start_Column => 9, End_Line => 1, End_Column => 12));
      Ignored := LM.Add_Symbol
        (Spec_Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 14, End_Line => 2, End_Column => 16),
         Profile_Summary => "(Count : Natural)");
      Ignored := LM.Add_Symbol
        (Spec_Analysis, "Counter", LM.Symbol_Type,
         (Start_Line => 3, Start_Column => 9, End_Line => 3, End_Column => 15));

      Flags.Is_Body := True;
      Ignored := LM.Add_Symbol
        (Body_Analysis, "Demo", LM.Symbol_Package_Body,
         (Start_Line => 1, Start_Column => 14, End_Line => 1, End_Column => 17),
         Flags => Flags);
      Ignored := LM.Add_Symbol
        (Body_Analysis, "Run", LM.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 14, End_Line => 3, End_Column => 16),
         Profile_Summary => "(Count : Natural)",
         Flags => Flags);

      LS.Put_Buffer_Analysis
        (Service, "/project/demo.ads", 1, 10, 1, Spec_Analysis);
      LS.Put_Buffer_Analysis
        (Service, "/project/demo.adb", 2, 20, 1, Body_Analysis);
   end Build_Service;

   function Current_Guard
     (Path : String := "wide.adb") return SG.Guarded_Semantic_Diagnostic_Model
   is
      Projection : SC.Semantic_Colour_Model;
      Key : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key (Path, 10, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Key, Key, Projection);
   end Current_Guard;

   function Rejected_Guard
     (Path : String := "wide.adb") return SG.Guarded_Semantic_Diagnostic_Model
   is
      Projection : SC.Semantic_Colour_Model;
      Produced : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key (Path, 10, 20, 30, 40, SC.Fingerprint (Projection));
      Current : constant SG.Diagnostic_Snapshot_Key :=
        SG.Make_Key (Path, 11, 20, 30, 40, SC.Fingerprint (Projection));
   begin
      return SG.Build (Produced, Current, Projection);
   end Rejected_Guard;

   function Wide_Model return WD.Wide_Semantic_Diagnostic_Model is
      Expression_Types : ET.Expression_Type_Model;
      Assignment_Contexts : AL.Assignment_Context_Model;
      Assignment_Context  : AL.Assignment_Context_Info;
      Assignments         : AL.Assignment_Legality_Model;
      Returns     : Editor.Ada_Return_Legality.Return_Legality_Model;
      Expressions : Editor.Ada_Conversion_Access_Aggregate_Legality.Semantic_Legality_Model;
      Flow        : Editor.Ada_Control_Flow_Legality.Flow_Legality_Model;
      Tasking     : Editor.Ada_Tasking_Protected_Legality.Tasking_Legality_Model;
      Tagged_Model      : Editor.Ada_Tagged_Derived_Legality.Tagged_Legality_Model;
      Instances   : Editor.Ada_Generic_Instance_Freezing_Representation_Legality.Instance_Legality_Model;
      Cross_Unit  : Editor.Ada_Cross_Unit_Semantic_Closure.Cross_Unit_Semantic_Model;
   begin
      Assignment_Context.Id := 1;
      Assignment_Context.Kind := AL.Assignment_Context_Assignment_Statement;
      Assignment_Context.Target_Node := Editor.Ada_Syntax_Tree.Node_Id (2_108);
      Assignment_Context.Source_Node := Editor.Ada_Syntax_Tree.Node_Id (2_109);
      Assignment_Context.Target_Mode := AL.Assignment_Target_Constant;
      Assignment_Context.Target_Subtype := To_Unbounded_String ("Integer");
      Assignment_Context.Source_Subtype := To_Unbounded_String ("Integer");
      Assignment_Context.Start_Line := 12;
      Assignment_Context.Start_Column := 3;
      Assignment_Context.End_Line := 12;
      Assignment_Context.End_Column := 17;
      AL.Add_Context (Assignment_Contexts, Assignment_Context);
      Assignments := AL.Build (Assignment_Contexts, Expression_Types);
      return WD.Build
        (Assignments, Returns, Expressions, Flow, Tasking, Tagged_Model,
         Instances, Cross_Unit);
   end Wide_Model;

   procedure Test_Service_Navigation_Completion_And_Hover
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Status  : LS.Index_Status;
      Decl    : LS.Language_Target;
      Body_Targets : LS.Language_Target_Set;
      Refs    : LS.Language_Target_Set;
      Symbols : LS.Language_Target_Set;
      Items   : LS.Completion_Result;
      Hover   : LS.Hover_Result;
   begin
      Build_Service (Service);
      Status := LS.Status (Service);
      Assert (Status.File_Count = 2, "service indexes both live snapshots");
      Assert (Status.Symbol_Count = 5, "service exposes indexed symbols");
      Assert (not Status.Overflowed, "small service index must not overflow");

      Decl := LS.Goto_Declaration (Service, "Run", LM.Symbol_Procedure);
      Assert (Decl.Status = LS.Service_Success, "declaration target available");
      Assert (To_String (Decl.Target.Path) = "/project/demo.ads",
              "declaration target should use the spec path");
      Assert (Decl.Target.Line = 2, "declaration line retained");

      Body_Targets := LS.Goto_Body
        (Service, "Run", LM.Symbol_Procedure, "(Count : Natural)");
      Assert (Body_Targets.Status = LS.Service_Success, "body target available");
      Assert (Natural (Body_Targets.Targets.Length) = 1, "single matching body");
      Assert (To_String (Body_Targets.Targets
              (Body_Targets.Targets.First_Index).Target.Path) =
              "/project/demo.adb", "body target should use body path");

      Refs := LS.Find_References (Service, "Run");
      Assert (Refs.Status = LS.Service_Success,
              "multi-location reference lookup is a successful result");
      Assert (Natural (Refs.Targets.Length) = 2,
              "reference lookup returns both declaration and body symbols");

      Symbols := LS.Workspace_Symbols (Service, "Run");
      Assert (Symbols.Status = LS.Service_Success,
              "workspace symbol lookup has project matches");
      Assert (Natural (Symbols.Targets.Length) = 2,
              "workspace symbol lookup returns project-wide declarations");
      Assert (To_String (Symbols.Targets
              (Symbols.Targets.First_Index).Target.Path) =
              "/project/demo.adb",
              "workspace symbols retain cross-file source paths");

      Items := LS.Complete (Service, "Co");
      Assert (Items.Status = LS.Service_Success, "completion has prefix hits");
      Assert (Natural (Items.Items.Length) = 1, "one Counter completion");
      Assert (To_String (Items.Items (Items.Items.First_Index).Label) =
              "Counter", "completion label retained");
      Assert (Items.Items (Items.Items.First_Index).Key.Buffer_Token = 1,
              "completion retains live-buffer navigation key");

      Items := LS.Complete (Service, "R");
      Assert (Items.Status = LS.Service_Success,
              "completion deduplicates spec/body symbols");
      Assert (Natural (Items.Items.Length) = 1,
              "Run completion should be listed once");
      Assert (Ada.Strings.Fixed.Index
                (To_String (Items.Items (Items.Items.First_Index).Detail),
                 "(Count : Natural)") > 0,
              "completion detail retains profile information");

      Hover := LS.Hover (Service, "Counter");
      Assert (Hover.Status = LS.Service_Success, "hover resolves symbol");
      Assert (To_String (Hover.Label) = "Counter", "hover label retained");
      Assert (Hover.Key.Buffer_Token = 1,
              "hover retains live-buffer navigation key");
   end Test_Service_Navigation_Completion_And_Hover;

   procedure Test_Service_Semantic_Request_Lifecycle_Guards_Results
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Req      : LS.Semantic_Request_Id;
      Active   : LS.Semantic_Request_Status;
      Decl     : LS.Language_Target;
      Targets  : LS.Language_Target_Set;
      Items    : LS.Completion_Result;
      Hover    : LS.Hover_Result;
      Preview  : LS.Rename_Preview;
      Backend  : LS.Semantic_Backend_Status;
      Capability : LS.Language_Service_Capabilities;
      Current_FP : Natural;
   begin
      Build_Service (Service);
      Current_FP := LM.Fingerprint
        (PI.File_Analysis_At (LS.Project_Index (Service), 1));
      Capability := LS.Capabilities (Service);
      Assert (Capability.Navigation_Supported
              and then Capability.Navigation_Ready
              and then Capability.References_Supported
              and then Capability.References_Ready
              and then Capability.Workspace_Symbols_Supported
              and then Capability.Workspace_Symbols_Ready
              and then Capability.Completion_Supported
              and then Capability.Completion_Ready
              and then Capability.Hover_Supported
              and then Capability.Hover_Ready
              and then Capability.Rename_Preview_Supported
              and then Capability.Rename_Preview_Ready
              and then Capability.Diagnostics_Supported
              and then Capability.Request_Lifecycle_Supported
              and then not Capability.Request_Cancellation_Available,
              "capabilities expose ready semantic language-service features");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Declaration,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Declaration, "Run",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Procedure)));
      Assert (LS.Semantic_Request_Is_Current (Service, Req),
              "fresh declaration request is current");
      Backend := LS.Backend_Status (Service);
      Assert (Backend.Semantic_Requests_Available
              and then Backend.Semantic_Requests_Cancellable
              and then Backend.Active_Request_Id = Req
              and then Backend.Active_Request_Kind =
                LS.Semantic_Request_Goto_Declaration
              and then Backend.Active_Request_Status =
                LS.Semantic_Request_Pending,
              "backend status exposes active semantic request lifecycle");
      Capability := LS.Capabilities (Service);
      Assert (Capability.Request_Cancellation_Available,
              "capabilities expose pending request cancellation availability");
      Decl := LS.Request_Goto_Declaration
        (Service, Req, "Run", LM.Symbol_Procedure);
      Active := LS.Active_Semantic_Request (Service);
      Backend := LS.Backend_Status (Service);
      Capability := LS.Capabilities (Service);
      Assert (Decl.Status = LS.Service_Success
              and then Active.Status = LS.Semantic_Request_Completed
              and then Active.Result_Status = LS.Service_Success
              and then not Backend.Semantic_Requests_Cancellable
              and then not Capability.Request_Cancellation_Available
              and then Backend.Active_Request_Status =
                LS.Semantic_Request_Completed,
              "request declaration completes against the current index");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Declaration,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Declaration, "Run",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Type)));
      Decl := LS.Request_Goto_Declaration
        (Service, Req, "Run", LM.Symbol_Procedure);
      Active := LS.Active_Semantic_Request (Service);
      Assert (Decl.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request declaration is scoped to the requested symbol kind");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Body,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Body, "Run", "(Count : Natural)",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Procedure)));
      Targets := LS.Request_Goto_Body
        (Service, Req, "Run", LM.Symbol_Procedure, "(Count : Natural)");
      Assert (Targets.Status = LS.Service_Success
              and then Natural (Targets.Targets.Length) = 1
              and then LS.Active_Semantic_Request (Service).Status =
                LS.Semantic_Request_Completed,
              "request body navigation completes with retained targets");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Spec,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Spec, "Run", "(Count : Natural)",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Procedure)));
      Targets := LS.Request_Goto_Spec
        (Service, Req, "Run", LM.Symbol_Procedure, "(Count : Natural)");
      Assert (Targets.Status = LS.Service_Success
              and then Natural (Targets.Targets.Length) = 1,
              "request spec navigation completes with retained targets");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Body,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Body, "Run", "(Count : Natural)",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Procedure)));
      Targets := LS.Request_Goto_Body
        (Service, Req, "Run", LM.Symbol_Procedure, "(Other : Natural)");
      Active := LS.Active_Semantic_Request (Service);
      Assert (Targets.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request body navigation is scoped to the requested profile");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Body,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Body, "Run", "(Count : Natural)",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Type)));
      Targets := LS.Request_Goto_Body
        (Service, Req, "Run", LM.Symbol_Procedure, "(Count : Natural)");
      Active := LS.Active_Semantic_Request (Service);
      Assert (Targets.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request body navigation is scoped to the requested symbol kind");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Spec,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Spec, "Run", "(Count : Natural)",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Procedure)));
      Targets := LS.Request_Goto_Spec
        (Service, Req, "Run", LM.Symbol_Procedure, "(Other : Natural)");
      Active := LS.Active_Semantic_Request (Service);
      Assert (Targets.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request spec navigation is scoped to the requested profile");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Spec,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Spec, "Run", "(Count : Natural)",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Type)));
      Targets := LS.Request_Goto_Spec
        (Service, Req, "Run", LM.Symbol_Procedure, "(Count : Natural)");
      Active := LS.Active_Semantic_Request (Service);
      Assert (Targets.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request spec navigation is scoped to the requested symbol kind");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Find_References, "Run");
      Targets := LS.Request_Find_References (Service, Req, "Run");
      Assert (Targets.Status = LS.Service_Success
              and then Natural (Targets.Targets.Length) = 2,
              "request references complete with project matches");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Workspace_Symbols, "Run");
      Targets := LS.Request_Workspace_Symbols (Service, Req, "Run");
      Assert (Targets.Status = LS.Service_Success
              and then Natural (Targets.Targets.Length) = 2
              and then LS.Active_Semantic_Request (Service).Kind =
                LS.Semantic_Request_Workspace_Symbols
              and then LS.Active_Semantic_Request (Service).Status =
                LS.Semantic_Request_Completed,
              "request workspace symbols complete with project matches");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Completion, "Co",
            Detail => Positive'Image (50)));
      Items := LS.Request_Complete (Service, Req, "Co");
      Assert (Items.Status = LS.Service_Success
              and then Natural (Items.Items.Length) = 1,
              "request completion completes with prefix hits");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Completion, "Co",
            Detail => Positive'Image (1)));
      Items := LS.Request_Complete (Service, Req, "Co", Limit => 50);
      Active := LS.Active_Semantic_Request (Service);
      Assert (Items.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request completion is scoped to the requested limit");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Hover, "Counter");
      Hover := LS.Request_Hover (Service, Req, "Counter");
      Assert (Hover.Status = LS.Service_Success
              and then To_String (Hover.Label) = "Counter",
              "request hover completes with symbol detail");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Rename,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Rename, "Counter",
            Detail => "New_Counter"));
      Preview := LS.Request_Preview_Rename
        (Service, Req, "Counter", "New_Counter");
      Assert (Preview.Status = LS.Service_Success
              and then Preview.Edit_Count = 1,
              "request rename preview completes with edit targets");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Rename,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Rename, "Counter",
            Detail => "Other_Counter"));
      Preview := LS.Request_Preview_Rename
        (Service, Req, "Counter", "New_Counter");
      Active := LS.Active_Semantic_Request (Service);
      Assert (Preview.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request rename preview is scoped to the requested new name");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Find_References,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Find_References, "Run",
            "/project/demo.ads", 1, 10, 1, Current_FP));
      Targets := LS.Request_Find_Current_References
        (Service, Req, "Run", "/project/demo.ads", 1, 10, 1, Current_FP);
      Assert (Targets.Status = LS.Service_Success
              and then LS.Active_Semantic_Request (Service).Status =
                LS.Semantic_Request_Completed,
              "request current references complete against a live snapshot");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Completion, "Co",
            "/project/demo.ads", 1, 10, 1, Current_FP,
            Detail => Positive'Image (50)));
      Items := LS.Request_Complete_Current
        (Service, Req, "Co", "/project/demo.ads", 1, 10, 1, Current_FP);
      Assert (Items.Status = LS.Service_Success
              and then LS.Active_Semantic_Request (Service).Kind =
                LS.Semantic_Request_Completion,
              "request current completion completes against a live snapshot");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Completion, "Co",
            "/project/demo.ads", 1, 10, 1, Current_FP,
            Detail => Positive'Image (1)));
      Items := LS.Request_Complete_Current
        (Service, Req, "Co", "/project/demo.ads", 1, 10, 1, Current_FP,
         Limit => 50);
      Active := LS.Active_Semantic_Request (Service);
      Assert (Items.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request current completion is scoped to the requested limit");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Hover,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Hover, "Counter",
            "/project/demo.ads", 1, 10, 1, Current_FP));
      Hover := LS.Request_Hover_Current
        (Service, Req, "Counter", "/project/demo.ads", 1, 10, 1,
         Current_FP);
      Assert (Hover.Status = LS.Service_Success
              and then LS.Active_Semantic_Request (Service).Status =
                LS.Semantic_Request_Completed,
              "request current hover completes against a live snapshot");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Rename,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Rename, "Counter",
            "/project/demo.ads", 1, 10, 1, Current_FP,
            Detail => "New_Counter"));
      Preview := LS.Request_Preview_Rename_Current
        (Service, Req, "Counter", "New_Counter", "/project/demo.ads",
         1, 10, 1, Current_FP);
      Assert (Preview.Status = LS.Service_Success
              and then Preview.Edit_Count = 1,
              "request current rename preview completes against a live snapshot");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Rename,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Rename, "Counter",
            "/project/demo.ads", 1, 10, 1, Current_FP,
            Detail => "Other_Counter"));
      Preview := LS.Request_Preview_Rename_Current
        (Service, Req, "Counter", "New_Counter", "/project/demo.ads",
         1, 10, 1, Current_FP);
      Active := LS.Active_Semantic_Request (Service);
      Assert (Preview.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request current rename preview is scoped to the requested new name");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Find_References,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Find_References, "Run",
            "/project/demo.ads", 1, 10, 1, Current_FP));
      Targets := LS.Request_Find_Current_References
        (Service, Req, "Run", "/project/demo.ads", 1, 11, 1, Current_FP);
      Active := LS.Active_Semantic_Request (Service);
      Assert (Targets.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request current references are scoped to the requested snapshot");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Completion, "Co",
            "/project/demo.ads", 1, 10, 1, Current_FP,
            Detail => Positive'Image (50)));
      Items := LS.Request_Complete_Current
        (Service, Req, "Co", "/project/demo.ads", 1, 11, 1, Current_FP);
      Active := LS.Active_Semantic_Request (Service);
      Assert (Items.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request current completion is scoped to the requested snapshot");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Hover,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Hover, "Counter",
            "/project/demo.ads", 1, 10, 1, Current_FP));
      Hover := LS.Request_Hover_Current
        (Service, Req, "Counter", "/project/demo.ads", 1, 11, 1,
         Current_FP);
      Active := LS.Active_Semantic_Request (Service);
      Assert (Hover.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request current hover is scoped to the requested snapshot");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Rename,
         LS.Semantic_Current_Request_Query_Key
           (LS.Semantic_Request_Rename, "Counter",
            "/project/demo.ads", 1, 10, 1, Current_FP,
            Detail => "New_Counter"));
      Preview := LS.Request_Preview_Rename_Current
        (Service, Req, "Counter", "New_Counter", "/project/demo.ads",
         1, 11, 1, Current_FP);
      Active := LS.Active_Semantic_Request (Service);
      Assert (Preview.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending,
              "request current rename preview is scoped to the requested snapshot");
      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Hover, "Counter");
      declare
         Superseded : constant LS.Semantic_Request_Id := Req;
      begin
         Req := LS.Begin_Semantic_Request
           (Service, LS.Semantic_Request_Completion,
            LS.Semantic_Request_Query_Key
              (LS.Semantic_Request_Completion, "Co",
               Detail => Positive'Image (50)));
         Active := LS.Active_Semantic_Request (Service);
         declare
            Previous : constant LS.Semantic_Request_Status :=
              LS.Previous_Semantic_Request (Service);
         begin
            Assert (Active.Id = Req
                    and then Active.Status = LS.Semantic_Request_Pending
                    and then Previous.Id = Superseded
                    and then Previous.Kind = LS.Semantic_Request_Hover
                    and then Previous.Status =
                      LS.Semantic_Request_Superseded
                    and then Previous.Result_Status = LS.Service_Stale
                    and then LS.Backend_Status
                      (Service).Previous_Request_Status =
                        LS.Semantic_Request_Superseded,
                    "starting a newer semantic request records the older request as superseded");
         end;
      end;

      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion, "Counter");
      Hover := LS.Request_Hover (Service, Req, "Counter");
      Active := LS.Active_Semantic_Request (Service);
      Assert (Hover.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending
              and then Active.Kind = LS.Semantic_Request_Completion,
              "request ids are scoped to their semantic operation kind");

      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Completion, "Co",
            Detail => Positive'Image (50)));
      Items := LS.Request_Complete (Service, Req, "R");
      Active := LS.Active_Semantic_Request (Service);
      Assert (Items.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending
              and then To_String (Active.Query) =
                LS.Semantic_Request_Query_Key
                  (LS.Semantic_Request_Completion, "Co",
                   Detail => Positive'Image (50)),
              "request ids are scoped to their original semantic query");

      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion);
      Items := LS.Request_Complete (Service, Req, "Co");
      Active := LS.Active_Semantic_Request (Service);
      Assert (Items.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Pending
              and then Length (Active.Query) = 0,
              "empty semantic request queries do not wildcard later requests");

      LS.Cancel_Semantic_Request (Service, Req);

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Hover, "Counter");
      LS.Cancel_Semantic_Request (Service, Req);
      Hover := LS.Request_Hover (Service, Req, "Counter");
      Active := LS.Active_Semantic_Request (Service);
      Backend := LS.Backend_Status (Service);
      Assert (Hover.Status = LS.Service_Unavailable
              and then Active.Status = LS.Semantic_Request_Cancelled
              and then not Backend.Semantic_Requests_Cancellable
              and then Backend.Active_Request_Status =
                LS.Semantic_Request_Cancelled,
              "cancelled request does not return semantic results");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Completion,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Completion, "R",
            Detail => Positive'Image (50)));
      Ignored := LM.Add_Symbol
        (Analysis, "Later", LM.Symbol_Object,
         (Start_Line => 1, Start_Column => 4, End_Line => 1, End_Column => 8));
      LS.Put_Buffer_Analysis
        (Service, "/project/later.ads", 3, 1, 1, Analysis);
      Items := LS.Request_Complete (Service, Req, "R");
      Active := LS.Active_Semantic_Request (Service);
      Backend := LS.Backend_Status (Service);
      Assert (Items.Status = LS.Service_Stale
              and then Active.Status = LS.Semantic_Request_Stale
              and then not LS.Semantic_Request_Is_Current (Service, Req)
              and then Backend.Active_Request_Status =
                LS.Semantic_Request_Stale,
              "stale request refuses results after index mutation");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Find_References, "Run");
      Targets := LS.Request_Find_References (Service, Req + 1, "Run");
      Assert (Targets.Status = LS.Service_Unavailable
              and then LS.Active_Semantic_Request (Service).Status =
                LS.Semantic_Request_Pending,
              "wrong request id cannot consume an active request");

      LS.Clear (Service);
      Active := LS.Active_Semantic_Request (Service);
      Capability := LS.Capabilities (Service);
      Assert (Active.Status = LS.Semantic_Request_No_Request
              and then Active.Id = LS.No_Semantic_Request,
              "clearing the service resets request lifecycle state");
      Assert (Capability.Navigation_Supported
              and then not Capability.Navigation_Ready
              and then Capability.Request_Lifecycle_Supported
              and then not Capability.Request_Cancellation_Available,
              "capabilities remain supported but not ready after service clear");
   end Test_Service_Semantic_Request_Lifecycle_Guards_Results;

   procedure Test_Service_Rename_And_Snapshot_Invalidation
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Preview : LS.Rename_Preview;
      Status  : LS.Index_Status;
      Analysis : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
   begin
      Build_Service (Service);
      Preview := LS.Preview_Rename (Service, "Counter", "New_Counter");
      Assert (Preview.Status = LS.Service_Success,
              "rename preview succeeds without conflicts");
      Assert (Preview.Edit_Count = 1, "rename preview counts affected symbols");
      Assert (Natural (Preview.Edits.Length) = 1,
              "rename preview exposes affected edit targets");

      Ignored := LM.Add_Symbol
        (Analysis, "New_Counter", LM.Symbol_Type,
         (Start_Line => 1, Start_Column => 9, End_Line => 1, End_Column => 19));
      LS.Put_Buffer_Analysis
        (Service, "/project/conflict.ads", 3, 1, 1, Analysis);

      Preview := LS.Preview_Rename (Service, "Counter", "New_Counter");
      Assert (Preview.Status = LS.Service_Ambiguous,
              "rename preview reports symbol-name conflicts");
      Assert (Preview.Conflict_Count = 1, "rename preview counts conflicts");
      Assert (Natural (Preview.Conflicts.Length) = 1,
              "rename preview exposes conflicting targets");

      LS.Invalidate_Path (Service, "/project/conflict.ads");
      Status := LS.Status (Service);
      Assert (Status.File_Count = 2,
              "path invalidation removes stale conflict snapshot");
      Assert (not LS.Contains_Current
        (Service, "/project/conflict.ads", 3, 1, 1, LM.Fingerprint (Analysis)),
        "invalidated conflict snapshot must not remain current");
   end Test_Service_Rename_And_Snapshot_Invalidation;

   procedure Test_Service_Compiler_Backend_Consumes_GNAT_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Clean_Lines : EP.Diagnostic_Text_Line_Array;
      Lines   : EP.Diagnostic_Text_Line_Array;
      Status  : LS.Compiler_Backend_Status;
      Path_Status : LS.Compiler_Backend_Status;
      Other_Path_Status : LS.Compiler_Backend_Status;
      Backend : LS.Semantic_Backend_Status;
      First   : LS.Compiler_Diagnostic;
      Before_Fingerprint : Natural;
   begin
      Backend := LS.Backend_Status (Service);
      Assert (Backend.Active_Backend = LS.Semantic_Backend_Internal_Index
              and then not Backend.Compiler_Backend_Available
              and then LS.Backend_Label (Backend) = "internal-index",
              "empty service reports internal semantic backend");
      Assert (not LS.Compiler_Status_For_Path
                (Service, "/work/demo/src/main.adb").Has_Run
              and then LS.Compiler_Status_For_Path
                (Service, "/work/demo/src/main.adb").Fingerprint = 0,
              "empty service reports no path compiler backend freshness");

      Clean_Lines.Append
        (To_Unbounded_String ("compiler run completed without diagnostics"));
      LS.Put_Compiler_Diagnostic_Lines
        (Service, Clean_Lines, Tool_Name => "gnat", Run_Fingerprint => 41);
      Backend := LS.Backend_Status (Service);
      Status := LS.Compiler_Status (Service);
      Assert (Status.Has_Run and then Status.Diagnostic_Count = 0,
              "clean compiler backend run records freshness without diagnostics");
      Assert (Backend.Active_Backend = LS.Semantic_Backend_Internal_Index
              and then Backend.Compiler_Backend_Available
              and then not Backend.Compiler_Diagnostics_Active
              and then not Backend.Diagnostics_From_Compiler
              and then LS.Backend_Label (Backend) = "internal-index",
              "clean compiler run does not promote inactive diagnostics backend");
      LS.Clear_Compiler_Backend (Service);

      Lines.Append
        (To_Unbounded_String ("src/main.adb:12:7: error: missing "";"""));
      Lines.Append
        (To_Unbounded_String ("src/main.adb:13:2: warning: variable ""X"" is not referenced"));
      Lines.Append
        (To_Unbounded_String ("not compiler output"));

      LS.Put_Compiler_Diagnostic_Lines
        (Service, Lines, Tool_Name => "gnat", Run_Fingerprint => 42);
      Status := LS.Compiler_Status (Service);
      Backend := LS.Backend_Status (Service);
      First := LS.Compiler_Diagnostic_At (Service, 1);
      Before_Fingerprint := Status.Fingerprint;

      Assert (Status.Has_Run, "compiler backend records an attempted compiler run");
      Assert (Status.Input_Count = 3,
              "compiler backend retains raw diagnostic input count");
      Assert (Status.Accepted_Count = 2,
              "compiler backend accepts GNAT diagnostic lines");
      Assert (Status.Diagnostic_Count = 2,
              "compiler backend stores accepted diagnostics");
      Assert (Status.Error_Count = 1 and then Status.Warning_Count = 1,
              "compiler backend preserves compiler severity counts");
      Assert (Backend.Active_Backend = LS.Semantic_Backend_GNAT_Compiler
              and then Backend.Compiler_Backend_Available
              and then Backend.Diagnostics_From_Compiler
              and then LS.Backend_Label (Backend) = "gnat-compiler",
              "compiler diagnostics promote the real GNAT backend");
      Assert (Status.Fingerprint /= 0,
              "compiler backend exposes deterministic freshness evidence");
      Assert (LS.Compiler_Diagnostic_Count (Service) = 2,
              "compiler diagnostic count matches backend status");
      Assert (First.Severity = EP.Compiler_Error,
              "first compiler diagnostic preserves error severity");
      Assert (To_String (First.File_Label) = "src/main.adb"
              and then First.Has_Location
              and then First.Line = 12
              and then First.Column = 7,
              "first compiler diagnostic preserves source location");
      Assert (To_String (First.Message) = "missing "";""",
              "first compiler diagnostic preserves compiler message text");
      Path_Status := LS.Compiler_Status_For_Path
        (Service, "/work/demo/src/main.adb");
      Other_Path_Status := LS.Compiler_Status_For_Path
        (Service, "/work/demo/src/other.adb");
      Assert (Path_Status.Has_Run
              and then Path_Status.Input_Count = Status.Input_Count,
              "path compiler backend status preserves compiler run provenance");
      Assert (Path_Status.Diagnostic_Count = 2
              and then Path_Status.Accepted_Count = 2
              and then Path_Status.Error_Count = 1
              and then Path_Status.Warning_Count = 1,
              "path compiler backend status scopes diagnostic severity counts");
      Assert (Path_Status.Fingerprint /= 0
              and then Path_Status.Fingerprint /=
                Other_Path_Status.Fingerprint,
              "path compiler backend status exposes path-specific freshness evidence");
      Assert (Other_Path_Status.Has_Run
              and then Other_Path_Status.Diagnostic_Count = 0
              and then Other_Path_Status.Error_Count = 0
              and then Other_Path_Status.Warning_Count = 0,
              "path compiler backend status reports empty matches without losing run state");
      Assert (LS.Compiler_Diagnostic_Count_For_Path
                (Service, "/work/demo/src/main.adb") = 2,
              "compiler backend resolves relative GNAT labels against absolute paths");
      Assert (LS.Compiler_Diagnostic_Count_For_Path
                (Service, "/work/demo/src/other.adb") = 0,
              "compiler backend path query excludes unrelated files");
      Assert (LS.Compiler_Diagnostic_At_For_Path
                (Service, "/work/demo/src/main.adb", 2).Severity =
                EP.Compiler_Warning,
              "compiler backend path query returns ordered matching diagnostics");
      Assert (not LS.Compiler_Diagnostic_At_For_Path
                (Service, "/work/demo/src/main.adb", 3).Has_Location,
              "compiler backend path query returns empty diagnostics out of range");

      LS.Put_Compiler_Diagnostic_Lines
        (Service, Lines, Tool_Name => "gnat", Run_Fingerprint => 43);
      Assert (LS.Compiler_Status (Service).Fingerprint /= Before_Fingerprint,
              "compiler backend freshness changes with compiler run fingerprint");

      declare
         Absolute_Lines : EP.Diagnostic_Text_Line_Array;
      begin
         Absolute_Lines.Append
           (To_Unbounded_String
              ("/work/demo/src/main.adb:14:3: info: absolute path diagnostic"));
         LS.Put_Compiler_Diagnostic_Lines
           (Service, Absolute_Lines, Tool_Name => "gnat", Run_Fingerprint => 44);
         Assert (LS.Compiler_Diagnostic_Count_For_Path
                   (Service, "src/main.adb") = 1,
                 "compiler backend resolves absolute GNAT labels against relative paths");
         Assert (LS.Compiler_Diagnostic_At_For_Path
                   (Service, "src/main.adb", 1).Severity =
                   EP.Compiler_Info,
                 "compiler backend returns diagnostics for symmetric path matches");
      end;

      LS.Clear (Service);
      Assert (not LS.Compiler_Status (Service).Has_Run
              and then LS.Compiler_Diagnostic_Count (Service) = 0,
              "clearing the language service clears compiler backend diagnostics");
   end Test_Service_Compiler_Backend_Consumes_GNAT_Diagnostics;

   procedure Test_Service_Compiler_Backend_Bounds_Diagnostics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Lines   : EP.Diagnostic_Text_Line_Array;
      Status  : LS.Compiler_Backend_Status;
   begin
      for I in 1 .. LS.Max_Compiler_Diagnostics + 3 loop
         Lines.Append
           (To_Unbounded_String
              ("src/bounded.adb:" &
               Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Left) &
               ":1: error: bounded compiler diagnostic"));
      end loop;

      LS.Put_Compiler_Diagnostic_Lines
        (Service, Lines, Tool_Name => "gprbuild", Run_Fingerprint => 99);
      Status := LS.Compiler_Status (Service);

      Assert (Status.Has_Run, "bounded compiler backend records the run");
      Assert (Status.Accepted_Count = LS.Max_Compiler_Diagnostics + 3,
              "bounded compiler backend still counts all accepted compiler rows");
      Assert (Status.Diagnostic_Count = LS.Max_Compiler_Diagnostics,
              "bounded compiler backend stores only the service diagnostic budget");
      Assert (LS.Compiler_Diagnostic_Count (Service) =
              LS.Max_Compiler_Diagnostics,
              "bounded compiler backend count is capped for IDE use");
      Assert (Status.Overflowed,
              "bounded compiler backend reports overflow when compiler output exceeds budget");
      Assert (Status.Error_Count = LS.Max_Compiler_Diagnostics + 3,
              "bounded compiler backend preserves full compiler severity totals");
   end Test_Service_Compiler_Backend_Bounds_Diagnostics;

   procedure Test_Service_Reindex_Preserves_Compiler_Backend
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Index   : PI.Index_State;
      Analysis : LM.Analysis_Result;
      Lines   : EP.Diagnostic_Text_Line_Array;
      Ignored : LM.Symbol_Id;
      Status  : LS.Compiler_Backend_Status;
   begin
      Lines.Append
        (To_Unbounded_String ("src/main.adb:4:2: warning: retained compiler diagnostic"));
      LS.Put_Compiler_Diagnostic_Lines
        (Service, Lines, Tool_Name => "gprbuild", Run_Fingerprint => 101);
      Status := LS.Compiler_Status (Service);
      Assert (Status.Has_Run and then Status.Warning_Count = 1,
              "compiler backend is populated before service reindex");

      Ignored := LM.Add_Symbol
        (Analysis, "Retained_Index", LM.Symbol_Procedure,
         (Start_Line => 1, Start_Column => 11, End_Line => 1, End_Column => 24));
      PI.Put_Analysis (Index, "src/retained_index.adb", 7, 1, 1, Analysis);
      LS.Put_Index (Service, Index);

      Assert (LS.Status (Service).File_Count = 1,
              "service reindex replaces the semantic project index");
      Assert (LS.Compiler_Status (Service).Has_Run
              and then LS.Compiler_Status (Service).Warning_Count = 1
              and then LS.Compiler_Diagnostic_Count (Service) = 1,
              "service reindex preserves compiler backend diagnostics");
      Assert (To_String (LS.Compiler_Diagnostic_At (Service, 1).File_Label) =
              "src/main.adb",
              "service reindex preserves compiler diagnostic payload");
   end Test_Service_Reindex_Preserves_Compiler_Backend;

   procedure Test_Service_Live_Semantic_Diagnostics_Publish_To_Backend
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := "src/live_semantic.ads";
      Source : constant String :=
        "package Live_Semantic is" & ASCII.LF &
        "   type Word is record" & ASCII.LF &
        "      A : Integer;" & ASCII.LF &
        "      B : Integer;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "   for Word use record" & ASCII.LF &
        "      A at 0 range 0 .. 7;" & ASCII.LF &
        "      B at 0 range 4 .. 15;" & ASCII.LF &
        "   end record;" & ASCII.LF &
        "end Live_Semantic;";
      Service : LS.Service_State;
      Index   : PI.Index_State;
      Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, Path);
      Before_Reindex : Natural;
      Found_Representation_Error : Boolean := False;
   begin
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path,
         Source,
         Buffer_Token         => 41,
         Buffer_Revision      => 42,
         Lifecycle_Generation => 43,
         Analysis             => Analysis);

      Assert (LS.Backend_Status (Service).Internal_Diagnostics_Active,
              "live semantic publish activates the service semantic backend");
      Assert (LS.Semantic_Diagnostic_Count (Service) > 0,
              "live semantic publish exposes diagnostics to IDE consumers");
      for I in 1 .. LS.Semantic_Diagnostic_Count (Service) loop
         declare
            Diagnostic : constant LS.Semantic_Diagnostic :=
              LS.Semantic_Diagnostic_At (Service, I);
         begin
            if Diagnostic.Severity = LS.Semantic_Error
              and then To_String (Diagnostic.Path) = Path
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "live-semantic") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "REPRESENTATION") > 0
            then
               Found_Representation_Error := True;
            end if;
         end;
      end loop;
      Assert (Found_Representation_Error,
              "live representation diagnostics preserve severity, path, and provenance");

      Before_Reindex := LS.Semantic_Diagnostic_Count (Service);
      PI.Put_Analysis
        (Index,
         Path,
         Buffer_Token         => 41,
         Buffer_Revision      => 42,
         Lifecycle_Generation => 43,
         Analysis             => Analysis);
      LS.Put_Index (Service, Index);

      Assert (LS.Status (Service).File_Count = 1,
              "service reindex receives the semantic project index");
      Assert (LS.Semantic_Diagnostic_Count (Service) = Before_Reindex,
              "service reindex preserves live semantic diagnostics");
   end Test_Service_Live_Semantic_Diagnostics_Publish_To_Backend;

   procedure Test_Service_Live_Semantic_Diagnostics_Include_Expressions
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := "src/live_expression.ads";
      Source : constant String :=
        "package Live_Expression is" & ASCII.LF &
        "   Q : Integer := new Boolean;" & ASCII.LF &
        "end Live_Expression;";
      Service : LS.Service_State;
      Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, Path);
      Found : Boolean := False;
   begin
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path,
         Source,
         Buffer_Token         => 51,
         Buffer_Revision      => 52,
         Lifecycle_Generation => 53,
         Analysis             => Analysis);

      for I in 1 .. LS.Semantic_Diagnostic_Count (Service) loop
         declare
            Diagnostic : constant LS.Semantic_Diagnostic :=
              LS.Semantic_Diagnostic_At (Service, I);
         begin
            if Diagnostic.Severity in LS.Semantic_Error | LS.Semantic_Warning
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Message), "expression") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "live-semantic") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "EXPRESSION") > 0
            then
               Found := True;
            end if;
         end;
      end loop;

      Assert (Found,
              "live semantic diagnostics include expression diagnostics in the service feed");
   end Test_Service_Live_Semantic_Diagnostics_Include_Expressions;

   procedure Test_Service_Live_Semantic_Diagnostics_Retain_Multiple_Files
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path_A : constant String := "src/live_expression_a.ads";
      Path_B : constant String := "src/live_expression_b.ads";
      Source_A : constant String :=
        "package Live_Expression_A is" & ASCII.LF &
        "   Q : Integer := new Boolean;" & ASCII.LF &
        "end Live_Expression_A;";
      Source_B : constant String :=
        "package Live_Expression_B is" & ASCII.LF &
        "   Q : Integer := new Float;" & ASCII.LF &
        "end Live_Expression_B;";
      Service : LS.Service_State;
      Analysis_A : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source_A, Path_A);
      Analysis_B : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source_B, Path_B);
   begin
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path_A,
         Source_A,
         Buffer_Token         => 151,
         Buffer_Revision      => 152,
         Lifecycle_Generation => 153,
         Analysis             => Analysis_A);
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path_B,
         Source_B,
         Buffer_Token         => 161,
         Buffer_Revision      => 162,
         Lifecycle_Generation => 163,
         Analysis             => Analysis_B);

      Assert (LS.Semantic_Diagnostic_Count_For_Path (Service, Path_A) > 0,
              "second live semantic publish preserves first file diagnostics");
      Assert (LS.Semantic_Diagnostic_Count_For_Path (Service, Path_B) > 0,
              "second live semantic publish records second file diagnostics");

      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path_A,
         Source_A,
         Buffer_Token         => 151,
         Buffer_Revision      => 154,
         Lifecycle_Generation => 153,
         Analysis             => Analysis_A);

      Assert (LS.Semantic_Diagnostic_Count_For_Path (Service, Path_A) > 0,
              "republishing one file keeps that file diagnostics current");
      Assert (LS.Semantic_Diagnostic_Count_For_Path (Service, Path_B) > 0,
              "republishing one file does not clear another file diagnostics");
   end Test_Service_Live_Semantic_Diagnostics_Retain_Multiple_Files;

   procedure Test_Service_Live_Semantic_Diagnostics_Include_Generics
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := "src/live_generic.ads";
      Source : constant String :=
        "package Live_Generic is" & ASCII.LF &
        "   subtype Small is Integer range 0 .. 10;" & ASCII.LF &
        "   generic" & ASCII.LF &
        "      Count : Small := 4;" & ASCII.LF &
        "      Scale : Float := 1.5;" & ASCII.LF &
        "   package Template is" & ASCII.LF &
        "   end Template;" & ASCII.LF &
        "   package Bad_Range is new Template (99, 2.5);" & ASCII.LF &
        "   package Bad_Type is new Template (1.25, 3);" & ASCII.LF &
        "end Live_Generic;";
      Service : LS.Service_State;
      Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, Path);
      Found : Boolean := False;
   begin
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path,
         Source,
         Buffer_Token         => 61,
         Buffer_Revision      => 62,
         Lifecycle_Generation => 63,
         Analysis             => Analysis);

      for I in 1 .. LS.Semantic_Diagnostic_Count (Service) loop
         declare
            Diagnostic : constant LS.Semantic_Diagnostic :=
              LS.Semantic_Diagnostic_At (Service, I);
         begin
            if Diagnostic.Severity = LS.Semantic_Error
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "live-semantic") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "GENERIC_CONTRACT") > 0
            then
               Found := True;
            end if;
         end;
      end loop;

      Assert (Found,
              "live semantic diagnostics include generic-contract diagnostics in the service feed");
   end Test_Service_Live_Semantic_Diagnostics_Include_Generics;

   procedure Test_Service_Live_Semantic_Diagnostics_Include_Stream_Profiles
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := "src/live_stream_profiles.ads";
      Source : constant String :=
        "package Live_Stream_Profiles is" & ASCII.LF &
        "   type Item is null record;" & ASCII.LF &
        "   type Other is null record;" & ASCII.LF &
        "   function Bad_Input (Stream : access Integer) return Other;" & ASCII.LF &
        "   procedure Bad_Output (Stream : access Integer);" & ASCII.LF &
        "   for Item'Input use Bad_Input;" & ASCII.LF &
        "   for Item'Output use Bad_Output;" & ASCII.LF &
        "end Live_Stream_Profiles;";
      Service : LS.Service_State;
      Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, Path);
      Found_Result_Mismatch : Boolean := False;
      Found_Arity_Mismatch  : Boolean := False;
   begin
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path,
         Source,
         Buffer_Token         => 81,
         Buffer_Revision      => 82,
         Lifecycle_Generation => 83,
         Analysis             => Analysis);

      for I in 1 .. LS.Semantic_Diagnostic_Count (Service) loop
         declare
            Diagnostic : constant LS.Semantic_Diagnostic :=
              LS.Semantic_Diagnostic_At (Service, I);
            Source_Text : constant String := To_String (Diagnostic.Source);
            Message_Text : constant String := To_String (Diagnostic.Message);
         begin
            if Diagnostic.Severity = LS.Semantic_Error
              and then To_String (Diagnostic.Path) = Path
              and then Ada.Strings.Fixed.Index (Source_Text, "live-semantic") > 0
              and then Ada.Strings.Fixed.Index (Source_Text, "REPRESENTATION") > 0
              and then Ada.Strings.Fixed.Index
                (Message_Text, "result subtype does not match") > 0
            then
               Found_Result_Mismatch := True;
            elsif Diagnostic.Severity = LS.Semantic_Error
              and then To_String (Diagnostic.Path) = Path
              and then Ada.Strings.Fixed.Index (Source_Text, "live-semantic") > 0
              and then Ada.Strings.Fixed.Index (Source_Text, "REPRESENTATION") > 0
              and then Ada.Strings.Fixed.Index
                (Message_Text, "wrong number of parameters") > 0
            then
               Found_Arity_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Found_Result_Mismatch,
              "live semantic diagnostics include stream Input result mismatches");
      Assert (Found_Arity_Mismatch,
              "live semantic diagnostics include stream handler arity mismatches");
   end Test_Service_Live_Semantic_Diagnostics_Include_Stream_Profiles;

   procedure Test_Service_Live_Semantic_Diagnostics_Include_Return_Mismatches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := "src/live_return_mismatch.adb";
      Source : constant String :=
        "package body Live_Return_Mismatch is" & ASCII.LF &
        "   function Make return Boolean is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      return 1;" & ASCII.LF &
        "   end Make;" & ASCII.LF &
        "end Live_Return_Mismatch;";
      Service : LS.Service_State;
      Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, Path);
      Found_Return_Mismatch : Boolean := False;
   begin
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path,
         Source,
         Buffer_Token         => 181,
         Buffer_Revision      => 182,
         Lifecycle_Generation => 183,
         Analysis             => Analysis);

      for I in 1 .. LS.Semantic_Diagnostic_Count (Service) loop
         declare
            Diagnostic : constant LS.Semantic_Diagnostic :=
              LS.Semantic_Diagnostic_At (Service, I);
            Source_Text : constant String := To_String (Diagnostic.Source);
            Message_Text : constant String := To_String (Diagnostic.Message);
         begin
            if Diagnostic.Severity = LS.Semantic_Error
              and then To_String (Diagnostic.Path) = Path
              and then Ada.Strings.Fixed.Index (Source_Text, "live-semantic") > 0
              and then Ada.Strings.Fixed.Index
                (Message_Text,
                 "return expression subtype is incompatible") > 0
            then
               Found_Return_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Found_Return_Mismatch,
              "live semantic diagnostics include ordinary return type mismatches");
   end Test_Service_Live_Semantic_Diagnostics_Include_Return_Mismatches;

   procedure Test_Service_Live_Semantic_Diagnostics_Include_Assignment_Mismatches
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := "src/live_assignment_mismatch.adb";
      Source : constant String :=
        "package body Live_Assignment_Mismatch is" & ASCII.LF &
        "   Count : Integer := 0;" & ASCII.LF &
        "   procedure Set is" & ASCII.LF &
        "   begin" & ASCII.LF &
        "      Count := True;" & ASCII.LF &
        "   end Set;" & ASCII.LF &
        "end Live_Assignment_Mismatch;";
      Service : LS.Service_State;
      Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, Path);
      Found_Assignment_Mismatch : Boolean := False;
   begin
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path,
         Source,
         Buffer_Token         => 191,
         Buffer_Revision      => 192,
         Lifecycle_Generation => 193,
         Analysis             => Analysis);

      for I in 1 .. LS.Semantic_Diagnostic_Count (Service) loop
         declare
            Diagnostic : constant LS.Semantic_Diagnostic :=
              LS.Semantic_Diagnostic_At (Service, I);
            Source_Text : constant String := To_String (Diagnostic.Source);
            Message_Text : constant String := To_String (Diagnostic.Message);
         begin
            if Diagnostic.Severity = LS.Semantic_Error
              and then To_String (Diagnostic.Path) = Path
              and then Ada.Strings.Fixed.Index (Source_Text, "live-semantic") > 0
              and then Ada.Strings.Fixed.Index
                (Message_Text,
                 "assignment source subtype is incompatible") > 0
            then
               Found_Assignment_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Found_Assignment_Mismatch,
              "live semantic diagnostics include ordinary assignment type mismatches");
   end Test_Service_Live_Semantic_Diagnostics_Include_Assignment_Mismatches;

   procedure Test_Service_Live_Semantic_Diagnostics_Use_Project_Cross_Unit_Lookup
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Library_Path : constant String := "src/library.ads";
      Client_Path  : constant String := "src/client_cross_lookup.adb";
      Library_Source : constant String :=
        "package Library is" & ASCII.LF &
        "   Exported : Integer;" & ASCII.LF &
        "end Library;";
      Client_Source : constant String :=
        "with Library;" & ASCII.LF &
        "package body Client_Cross_Lookup is" & ASCII.LF &
        "   Value : Boolean := Library.Exported;" & ASCII.LF &
        "end Client_Cross_Lookup;";
      Service : LS.Service_State;
      Index   : PI.Index_State;
      Library_Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Library_Source, Library_Path);
      Client_Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Client_Source, Client_Path);
      Found_Cross_Unit_Type_Mismatch : Boolean := False;
   begin
      PI.Put_Analysis
        (Index,
         Library_Path,
         Buffer_Token         => 91,
         Buffer_Revision      => 92,
         Lifecycle_Generation => 93,
         Analysis             => Library_Analysis);
      PI.Put_Analysis
        (Index,
         Client_Path,
         Buffer_Token         => 94,
         Buffer_Revision      => 95,
         Lifecycle_Generation => 96,
         Analysis             => Client_Analysis);
      LS.Put_Index (Service, Index);

      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Client_Path,
         Client_Source,
         Buffer_Token         => 94,
         Buffer_Revision      => 95,
         Lifecycle_Generation => 96,
         Analysis             => Client_Analysis);

      for I in 1 .. LS.Semantic_Diagnostic_Count (Service) loop
         declare
            Diagnostic : constant LS.Semantic_Diagnostic :=
              LS.Semantic_Diagnostic_At (Service, I);
         begin
            if Diagnostic.Severity = LS.Semantic_Error
              and then To_String (Diagnostic.Path) = Client_Path
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "live-semantic") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Message), "expected subtype") > 0
            then
               Found_Cross_Unit_Type_Mismatch := True;
            end if;
         end;
      end loop;

      Assert (Found_Cross_Unit_Type_Mismatch,
              "live semantic diagnostics use project cross-unit lookup for selected-name typing");
   end Test_Service_Live_Semantic_Diagnostics_Use_Project_Cross_Unit_Lookup;

   procedure Test_Service_Live_Semantic_Diagnostics_Include_Cross_Units
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Path : constant String := "src/client.ads";
      Source : constant String :=
        "with Missing_Dep;" & ASCII.LF &
        "package Client is" & ASCII.LF &
        "   Q : Integer := new Boolean;" & ASCII.LF &
        "end Client;";
      Service : LS.Service_State;
      Index   : PI.Index_State;
      Analysis : constant LM.Analysis_Result :=
        Editor.Ada_Declaration_Parser.Parse (Source, Path);
      First_Count : Natural;
      Found_Expression : Boolean := False;
      Found_Cross_Unit : Boolean := False;
   begin
      Editor.Ada_Live_Semantic_Diagnostics.Publish
        (Service,
         Path,
         Source,
         Buffer_Token         => 71,
         Buffer_Revision      => 72,
         Lifecycle_Generation => 73,
         Analysis             => Analysis);
      PI.Put_Analysis
        (Index,
         Path,
         Buffer_Token         => 71,
         Buffer_Revision      => 72,
         Lifecycle_Generation => 73,
         Analysis             => Analysis);
      LS.Put_Index (Service, Index);
      Editor.Ada_Live_Semantic_Diagnostics.Publish_Cross_Unit
        (Service, Index);
      First_Count := LS.Semantic_Diagnostic_Count (Service);
      Editor.Ada_Live_Semantic_Diagnostics.Publish_Cross_Unit
        (Service, Index);

      Assert (LS.Semantic_Diagnostic_Count (Service) = First_Count,
              "repeated cross-unit publish replaces previous cross-unit diagnostics");

      for I in 1 .. LS.Semantic_Diagnostic_Count (Service) loop
         declare
            Diagnostic : constant LS.Semantic_Diagnostic :=
              LS.Semantic_Diagnostic_At (Service, I);
         begin
            if To_String (Diagnostic.Path) = Path
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "EXPRESSION") > 0
            then
               Found_Expression := True;
            elsif To_String (Diagnostic.Path) = Path
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Source), "live-semantic-cross-unit") > 0
              and then Ada.Strings.Fixed.Index
                (To_String (Diagnostic.Message), "missing") > 0
            then
               Found_Cross_Unit := True;
            end if;
         end;
      end loop;

      Assert (Found_Expression,
              "cross-unit live publish preserves existing per-file semantic diagnostics");
      Assert (Found_Cross_Unit,
              "live semantic diagnostics include cross-unit diagnostics in the service feed");
   end Test_Service_Live_Semantic_Diagnostics_Include_Cross_Units;

   procedure Test_Service_Internal_Semantic_Diagnostics_Are_Visible
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Backend : LS.Semantic_Backend_Status;
      Status  : LS.Semantic_Diagnostic_Status;
      Path_Status : LS.Semantic_Diagnostic_Status;
      First   : LS.Semantic_Diagnostic;
      Analysis : LM.Analysis_Result;
      Ignored : LM.Symbol_Id;
      Before_Fingerprint : Natural;
   begin
      LS.Put_Semantic_Diagnostic
        (Service,
         (Severity     => LS.Semantic_Error,
          Message      => To_Unbounded_String ("undefined identifier Foo"),
          Path         => To_Unbounded_String ("src/main.adb"),
          Has_Location => True,
          Line         => 12,
          Column       => 7,
          Source       => To_Unbounded_String ("cross-unit lookup"),
          others       => <>));
      LS.Put_Semantic_Diagnostic
        (Service,
         (Severity     => LS.Semantic_Warning,
          Message      => To_Unbounded_String ("private child hidden"),
          Path         => To_Unbounded_String ("src/main.adb"),
          Has_Location => True,
          Line         => 13,
          Column       => 3,
          Source       => To_Unbounded_String ("child visibility"),
          others       => <>));
      LS.Put_Semantic_Diagnostic
        (Service,
         (Severity     => LS.Semantic_Hint,
          Message      => To_Unbounded_String ("candidate imported by use clause"),
          Path         => To_Unbounded_String ("src/other.adb"),
          Has_Location => False,
          Line         => 0,
          Column       => 0,
          Source       => To_Unbounded_String ("semantic lookup"),
          others       => <>));

      Status := LS.Semantic_Diagnostics_Status (Service);
      Backend := LS.Backend_Status (Service);
      First := LS.Semantic_Diagnostic_At (Service, 1);
      Before_Fingerprint := Status.Fingerprint;

      Assert (Status.Diagnostic_Count = 3,
              "semantic backend stores internal diagnostic rows");
      Assert (Status.Error_Count = 1
              and then Status.Warning_Count = 1
              and then Status.Hint_Count = 1,
              "semantic backend counts internal diagnostic severities");
      Assert (Status.Fingerprint /= 0,
              "semantic diagnostics expose deterministic freshness evidence");
      Assert (Backend.Active_Backend = LS.Semantic_Backend_Internal_Index
              and then Backend.Internal_Diagnostics_Active
              and then Backend.Diagnostics_From_Internal
              and then not Backend.Diagnostics_From_Compiler,
              "internal semantic diagnostics activate the IDE semantic backend");
      Assert (To_String (First.Message) = "undefined identifier Foo"
              and then First.Severity = LS.Semantic_Error
              and then First.Line = 12
              and then First.Column = 7,
              "semantic diagnostic payload is retained");

      Path_Status := LS.Semantic_Diagnostics_Status_For_Path
        (Service, "/work/demo/src/main.adb");
      Assert (Path_Status.Diagnostic_Count = 2
              and then Path_Status.Error_Count = 1
              and then Path_Status.Warning_Count = 1,
              "semantic diagnostics are filterable by source path");
      Assert (LS.Semantic_Diagnostic_Count_For_Path
                (Service, "/work/demo/src/main.adb") = 2,
              "semantic diagnostic path count uses normalized suffix matching");
      Assert (LS.Semantic_Diagnostic_At_For_Path
                (Service, "/work/demo/src/main.adb", 2).Severity =
              LS.Semantic_Warning,
              "semantic diagnostic path query preserves filtered order");
      Assert (To_String (LS.Semantic_Diagnostic_At_For_Path
                (Service, "/work/demo/src/missing.adb", 1).Message) = "",
              "semantic diagnostic path query returns an empty row out of range");

      Ignored := LM.Add_Symbol
        (Analysis, "Still_Indexed", LM.Symbol_Object,
         (Start_Line => 1, Start_Column => 4, End_Line => 1, End_Column => 16));
      LS.Put_Buffer_Analysis
        (Service, "/work/demo/src/main.adb", 44, 1, 1, Analysis);
      Assert (LS.Semantic_Diagnostics_Status (Service).Fingerprint =
              Before_Fingerprint,
              "adding index snapshots does not discard semantic diagnostics");

      LS.Clear_Semantic_Diagnostics (Service);
      Assert (LS.Semantic_Diagnostic_Count (Service) = 0
              and then not LS.Backend_Status (Service).Internal_Diagnostics_Active,
              "semantic diagnostics can be cleared without clearing the index");
      Assert (LS.Status (Service).File_Count = 1,
              "semantic diagnostic clear preserves indexed snapshots");
   end Test_Service_Internal_Semantic_Diagnostics_Are_Visible;

   procedure Test_Service_Internal_Semantic_Diagnostics_Are_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Status  : LS.Semantic_Diagnostic_Status;
   begin
      for I in 1 .. LS.Max_Semantic_Diagnostics + 2 loop
         LS.Put_Semantic_Diagnostic
           (Service,
            (Severity     => LS.Semantic_Info,
             Message      => To_Unbounded_String
               ("bounded semantic diagnostic" &
                Ada.Strings.Fixed.Trim (Natural'Image (I), Ada.Strings.Left)),
             Path         => To_Unbounded_String ("src/bounded.adb"),
             Has_Location => True,
             Line         => I,
             Column       => 1,
             Source       => To_Unbounded_String ("semantic backend"),
             others       => <>));
      end loop;

      Status := LS.Semantic_Diagnostics_Status (Service);
      Assert (Status.Diagnostic_Count = LS.Max_Semantic_Diagnostics,
              "semantic backend stores only the IDE diagnostic budget");
      Assert (LS.Semantic_Diagnostic_Count (Service) =
              LS.Max_Semantic_Diagnostics,
              "semantic diagnostic count is capped for GUI use");
      Assert (Status.Info_Count = LS.Max_Semantic_Diagnostics + 2,
              "semantic backend still accounts for all produced rows");
      Assert (Status.Overflowed,
              "semantic backend reports overflow when internal diagnostics exceed budget");
   end Test_Service_Internal_Semantic_Diagnostics_Are_Bounded;

   procedure Test_Service_Consumes_Guarded_Semantic_Diagnostic_Feed
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Wide    : constant WD.Wide_Semantic_Diagnostic_Model := Wide_Model;
      Feed    : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Wide_Legality (Current_Guard ("src/wide.adb"), Wide);
      Stale_Feed : constant SF.Semantic_Diagnostic_Feed_Model :=
        SF.Build_With_Wide_Legality
          (Rejected_Guard ("src/wide.adb"), Wide,
           Wide_Rejected_Count => WD.Diagnostic_Count (Wide));
      Status : LS.Semantic_Diagnostic_Status;
      First  : LS.Semantic_Diagnostic;
   begin
      Assert (SF.Current (Feed) and then SF.Entry_Count (Feed) >= 1,
              "test feed must expose current semantic diagnostic rows");

      LS.Put_Semantic_Diagnostic_Feed
        (Service, "/project/src/wide.adb", Feed, "wide-feed");
      Status := LS.Semantic_Diagnostics_Status (Service);
      First := LS.Semantic_Diagnostic_At (Service, 1);

      Assert (Status.Diagnostic_Count = SF.Entry_Count (Feed),
              "service consumes every current semantic feed row");
      Assert (Status.Error_Count = SF.Error_Count (Feed)
              and then Status.Warning_Count = SF.Warning_Count (Feed)
              and then Status.Info_Count = SF.Info_Count (Feed),
              "service preserves feed severity totals");
      Assert (To_String (First.Path) = "/project/src/wide.adb"
              and then First.Has_Location
              and then First.Line = 12
              and then First.Column = 3,
              "service maps feed rows to path-scoped diagnostics");
      Assert (To_String (First.Source)'Length > 0
              and then To_String (First.Message)'Length > 0,
              "service preserves feed provenance and message text");
      Assert
        (First.Has_Command_Descriptor
         and then To_String (First.Command_Descriptor.Display_Label)'Length > 0,
         "service carries descriptor-backed quick-fix metadata from live semantic feeds");
      Assert (LS.Semantic_Diagnostic_Count_For_Path
                (Service, "src/wide.adb") = SF.Entry_Count (Feed),
              "service path queries include feed diagnostics");
      Assert (LS.Backend_Status (Service).Diagnostics_From_Internal,
              "feed diagnostics activate internal backend status");

      LS.Put_Semantic_Diagnostic_Feed
        (Service, "/project/src/wide.adb", Stale_Feed, "wide-feed");
      Assert (LS.Semantic_Diagnostic_Count (Service) = 0
              and then not LS.Backend_Status (Service).Diagnostics_From_Internal,
              "stale semantic feed clears active diagnostics instead of leaking rows");
      Assert (LS.Semantic_Diagnostics_Status (Service).Fingerprint /= 0,
              "stale semantic feed still leaves deterministic freshness evidence");
   end Test_Service_Consumes_Guarded_Semantic_Diagnostic_Feed;

   procedure Test_Service_Rename_Rejects_Invalid_New_Names
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Preview : LS.Rename_Preview;

      procedure Expect_Unavailable (New_Name : String; Message : String) is
      begin
         Preview := LS.Preview_Rename (Service, "Counter", New_Name);
         Assert (Preview.Status = LS.Service_Unavailable, Message);
         Assert (Preview.Edit_Count = 0 and then Preview.Conflict_Count = 0,
                 Message & " leaves no partial edit counts");
         Assert (Preview.Edits.Is_Empty and then Preview.Conflicts.Is_Empty,
                 Message & " leaves no partial target sets");
      end Expect_Unavailable;

      procedure Expect_Old_Unavailable (Old_Name : String; Message : String) is
      begin
         Preview := LS.Preview_Rename (Service, Old_Name, "New_Counter");
         Assert (Preview.Status = LS.Service_Unavailable, Message);
         Assert (Preview.Edit_Count = 0 and then Preview.Conflict_Count = 0,
                 Message & " leaves no partial edit counts");
         Assert (Preview.Edits.Is_Empty and then Preview.Conflicts.Is_Empty,
                 Message & " leaves no partial target sets");
      end Expect_Old_Unavailable;
   begin
      Build_Service (Service);

      Expect_Old_Unavailable ("1Counter",
        "rename preview rejects old identifiers that start with digits");
      Expect_Old_Unavailable ("Old-Counter",
        "rename preview rejects malformed old identifiers");
      Expect_Unavailable ("Counter",
        "rename preview rejects no-op same-name renames");
      Expect_Unavailable ("1Counter",
        "rename preview rejects identifiers that start with digits");
      Expect_Unavailable ("New-Counter",
        "rename preview rejects non-identifier punctuation");
      Expect_Unavailable ("Return",
        "rename preview rejects Ada reserved words");
      Expect_Unavailable ("New__Counter",
        "rename preview rejects doubled underscores");
      Expect_Unavailable ("New_Counter_",
        "rename preview rejects trailing underscores");
   end Test_Service_Rename_Rejects_Invalid_New_Names;

   procedure Test_Service_Current_References_Report_Stale_Snapshots
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      Path_Service : LS.Service_State;
      Current_Missing_Service : LS.Service_State;
      Analysis : LM.Analysis_Result;
      Path_Analysis : LM.Analysis_Result;
      Project_Analysis : LM.Analysis_Result;
      Current_Missing_Stale : LM.Analysis_Result;
      Current_Missing_Current : LM.Analysis_Result;
      Ignored  : LM.Symbol_Id;
      Decl     : LS.Language_Target;
      Refs     : LS.Language_Target_Set;
      Hover    : LS.Hover_Result;
      Items    : LS.Completion_Result;
      Preview  : LS.Rename_Preview;
      Conflict_Analysis : LM.Analysis_Result;
      Fingerprint : Natural;
      Path_Fingerprint : Natural;
      Current_Missing_Fingerprint : Natural;
   begin
      Ignored := LM.Add_Symbol
        (Analysis, "Current_Name", LM.Symbol_Object,
         (Start_Line => 4, Start_Column => 7, End_Line => 4, End_Column => 18));
      Fingerprint := LM.Fingerprint (Analysis);
      LS.Put_Buffer_Analysis
        (Service, "/project/current.ads", 9, 12, 3, Analysis);
      Ignored := LM.Add_Symbol
        (Project_Analysis, "Current_Name", LM.Symbol_Object,
         (Start_Line => 8, Start_Column => 4, End_Line => 8, End_Column => 15));
      Ignored := LM.Add_Symbol
        (Project_Analysis, "Current_Helper", LM.Symbol_Object,
         (Start_Line => 9, Start_Column => 4, End_Line => 9, End_Column => 17));
      LS.Put_Buffer_Analysis
        (Service, "/project/other.ads", 8, 1, 1, Project_Analysis);

      Decl := LS.Goto_Declaration_Current
        (Service, "Current_Name", LM.Symbol_Object, "/project/current.ads",
         9, 12, 3, Fingerprint);
      Assert (Decl.Status = LS.Service_Success,
              "current declaration lookup succeeds for an exact snapshot stamp");
      Assert (To_String (Decl.Target.Path) = "/project/current.ads",
              "current declaration lookup returns exact snapshot target");

      Decl := LS.Goto_Declaration_Current
        (Service, "Current_Name", LM.Symbol_Object, "/project/current.ads",
         9, 13, 3, Fingerprint);
      Assert (Decl.Status = LS.Service_Stale,
              "current declaration lookup reports stale same-buffer snapshots");

      Decl := LS.Goto_Declaration_Current
        (Service, "Missing_Name", LM.Symbol_Object, "/project/current.ads",
         9, 12, 3, Fingerprint);
      Assert (Decl.Status = LS.Service_Unavailable,
              "missing current declaration lookup is unavailable, not stale");

      Refs := LS.Find_Current_References
        (Service, "Current_Name", "/project/current.ads", 9, 12, 3,
         Fingerprint);
      Assert (Refs.Status = LS.Service_Success,
              "current reference lookup succeeds for an exact snapshot stamp");
      Assert (Natural (Refs.Targets.Length) = 2,
              "current reference lookup returns exact snapshot and project matches");

      Refs := LS.Find_Current_References
        (Service, "Current_Name", "/project/current.ads", 9, 13, 3,
         Fingerprint);
      Assert (Refs.Status = LS.Service_Stale,
              "current reference lookup reports stale same-buffer snapshots");
      Assert (Refs.Targets.Is_Empty,
              "stale current reference lookup exposes no stale targets");

      Refs := LS.Find_Current_References
        (Service, "Missing_Name", "/project/current.ads", 9, 12, 3,
         Fingerprint);
      Assert (Refs.Status = LS.Service_Unavailable,
              "missing current reference lookup is unavailable, not stale");
      Assert (Refs.Targets.Is_Empty,
              "missing current reference lookup has no targets");

      Hover := LS.Hover_Current
        (Service, "Current_Name", "/project/current.ads", 9, 12, 3,
         Fingerprint);
      Assert (Hover.Status = LS.Service_Success,
              "current hover succeeds for an exact snapshot stamp");
      Assert (To_String (Hover.Label) = "Current_Name",
              "current hover returns exact snapshot label");

      Hover := LS.Hover_Current
        (Service, "Current_Name", "/project/current.ads", 9, 13, 3,
         Fingerprint);
      Assert (Hover.Status = LS.Service_Stale,
              "current hover reports stale same-buffer snapshots");

      Hover := LS.Hover_Current
        (Service, "Missing_Name", "/project/current.ads", 9, 12, 3,
         Fingerprint);
      Assert (Hover.Status = LS.Service_Unavailable,
              "missing current hover is unavailable, not stale");

      Items := LS.Complete_Current
        (Service, "Current", "/project/current.ads", 9, 12, 3,
         Fingerprint);
      Assert (Items.Status = LS.Service_Success,
              "current completion succeeds for an exact snapshot stamp");
      Assert (Natural (Items.Items.Length) = 2,
              "current completion returns exact snapshot and project matches");

      Items := LS.Complete_Current
        (Service, "Current", "/project/current.ads", 9, 13, 3,
         Fingerprint);
      Assert (Items.Status = LS.Service_Stale,
              "current completion reports stale same-buffer snapshots");
      Assert (Items.Items.Is_Empty,
              "stale current completion exposes no stale items");

      Items := LS.Complete_Current
        (Service, "Missing", "/project/current.ads", 9, 12, 3,
         Fingerprint);
      Assert (Items.Status = LS.Service_Unavailable,
              "missing current completion is unavailable, not stale");

      Preview := LS.Preview_Rename_Current
        (Service, "Current_Name", "Renamed_Current", "/project/current.ads",
         9, 12, 3, Fingerprint);
      Assert (Preview.Status = LS.Service_Success,
              "current rename preview succeeds for an exact snapshot stamp");
      Assert (Preview.Edit_Count = 2,
              "current rename preview returns exact snapshot and project edits");

      Preview := LS.Preview_Rename_Current
        (Service, "Current_Name", "type", "/project/current.ads",
         9, 12, 3, Fingerprint);
      Assert (Preview.Status = LS.Service_Unavailable,
              "current rename preview rejects reserved-word targets");
      Assert (Preview.Edits.Is_Empty and then Preview.Conflicts.Is_Empty,
              "reserved-word current rename preview exposes no partial targets");

      Preview := LS.Preview_Rename_Current
        (Service, "Current_Name", "Renamed_Current", "/project/current.ads",
         9, 13, 3, Fingerprint);
      Assert (Preview.Status = LS.Service_Stale,
              "current rename preview reports stale same-buffer snapshots");
      Assert (Preview.Edits.Is_Empty and then Preview.Conflicts.Is_Empty,
              "stale current rename preview exposes no stale targets");

      Ignored := LM.Add_Symbol
        (Conflict_Analysis, "Renamed_Current", LM.Symbol_Object,
         (Start_Line => 1, Start_Column => 4, End_Line => 1, End_Column => 18));
      LS.Put_Buffer_Analysis
        (Service, "/project/conflict-current.ads", 10, 1, 1,
         Conflict_Analysis);
      Preview := LS.Preview_Rename_Current
        (Service, "Current_Name", "Renamed_Current", "/project/current.ads",
         9, 12, 3, Fingerprint);
      Assert (Preview.Status = LS.Service_Ambiguous,
              "current rename preview preserves broad project conflict checks");
      Assert (Preview.Edit_Count = 2 and then Preview.Conflict_Count = 1,
              "current rename preview reports edit and conflict counts");

      Ignored := LM.Add_Symbol
        (Path_Analysis, "Path_Name", LM.Symbol_Object,
         (Start_Line => 2, Start_Column => 5, End_Line => 2, End_Column => 13));
      Path_Fingerprint := LM.Fingerprint (Path_Analysis);
      LS.Put_Buffer_Analysis
        (Path_Service, "/project//normalized.ads/", 11, 7, 1,
         Path_Analysis);

      Refs := LS.Find_Current_References
        (Path_Service, "Path_Name", "/project/normalized.ads", 11, 8, 1,
         Path_Fingerprint);
      Assert (Refs.Status = LS.Service_Stale,
              "current references normalize paths when detecting stale snapshots");
      Items := LS.Complete_Current
        (Path_Service, "Path", "/project/normalized.ads", 11, 8, 1,
         Path_Fingerprint);
      Assert (Items.Status = LS.Service_Stale,
              "current completions normalize paths when detecting stale snapshots");
      Hover := LS.Hover_Current
        (Path_Service, "Path_Name", "/project/normalized.ads", 11, 8, 1,
         Path_Fingerprint);
      Assert (Hover.Status = LS.Service_Stale,
              "current hover normalizes paths when detecting stale snapshots");
      Preview := LS.Preview_Rename_Current
        (Path_Service, "Path_Name", "Path_Renamed",
         "/project/normalized.ads", 11, 8, 1, Path_Fingerprint);
      Assert (Preview.Status = LS.Service_Stale,
              "current rename preview normalizes paths when detecting stale snapshots");

      Ignored := LM.Add_Symbol
        (Current_Missing_Stale, "Old_Path_Name", LM.Symbol_Object,
         (Start_Line => 2, Start_Column => 5, End_Line => 2, End_Column => 17));
      Ignored := LM.Add_Symbol
        (Current_Missing_Current, "Different_Name", LM.Symbol_Object,
         (Start_Line => 3, Start_Column => 5, End_Line => 3, End_Column => 18));
      Current_Missing_Fingerprint := LM.Fingerprint (Current_Missing_Current);
      LS.Put_Buffer_Analysis
        (Current_Missing_Service, "/project//gone.ads/", 12, 7, 1,
         Current_Missing_Stale);
      LS.Put_Buffer_Analysis
        (Current_Missing_Service, "/project/gone.ads", 12, 8, 1,
         Current_Missing_Current);
      Assert (LS.Status (Current_Missing_Service).File_Count = 1,
              "normalized path updates replace existing indexed snapshots");

      Decl := LS.Goto_Declaration_Current
        (Current_Missing_Service, "Old_Path_Name", LM.Symbol_Object,
         "/project/gone.ads", 12, 8, 1, Current_Missing_Fingerprint);
      Assert (Decl.Status = LS.Service_Unavailable,
              "current declaration prefers current missing symbol over stale path spelling");
      Refs := LS.Find_Current_References
        (Current_Missing_Service, "Old_Path_Name", "/project/gone.ads", 12, 8, 1,
         Current_Missing_Fingerprint);
      Assert (Refs.Status = LS.Service_Unavailable,
              "current references prefer current missing symbol over stale path spelling");
      Hover := LS.Hover_Current
        (Current_Missing_Service, "Old_Path_Name", "/project/gone.ads", 12, 8, 1,
         Current_Missing_Fingerprint);
      Assert (Hover.Status = LS.Service_Unavailable,
              "current hover prefers current missing symbol over stale path spelling");
      Preview := LS.Preview_Rename_Current
        (Current_Missing_Service, "Old_Path_Name", "Renamed_Path_Name",
         "/project/gone.ads", 12, 8, 1, Current_Missing_Fingerprint);
      Assert (Preview.Status = LS.Service_Unavailable,
              "current rename preview prefers current missing symbol over stale path spelling");
   end Test_Service_Current_References_Report_Stale_Snapshots;

   procedure Test_Service_Completion_Reports_Overflowed_Index
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service  : LS.Service_State;
      Analysis : LM.Analysis_Result;
      Items    : LS.Completion_Result;
      Ignored  : LM.Symbol_Id;
   begin
      for I in 1 .. LM.Max_Analysis_Symbols + 1 loop
         Ignored := LM.Add_Symbol
           (Analysis,
            (if I = 1 then "Candidate" else "Filler" & Natural'Image (I)),
            LM.Symbol_Object,
            (Start_Line => Positive (I), Start_Column => 4,
             End_Line => Positive (I), End_Column => 12));
      end loop;

      Assert (LM.Overflowed (Analysis),
              "test analysis must be overflowed before indexing");

      LS.Put_Buffer_Analysis
        (Service, "/project/large.ads", 4, 1, 1, Analysis);

      Items := LS.Complete (Service, "Ca");
      Assert (Items.Status = LS.Service_Overflow,
              "completion must not hide a truncated project index");
      Assert (Items.Items.Is_Empty,
              "overflowed completion should not expose partial candidates");
   end Test_Service_Completion_Reports_Overflowed_Index;

   procedure Test_Service_Completions_Are_Deterministic_And_Limited
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      First   : LM.Analysis_Result;
      Second  : LM.Analysis_Result;
      Items   : LS.Completion_Result;
      Ignored : LM.Symbol_Id;
   begin
      Ignored := LM.Add_Symbol
        (First, "Zoo", LM.Symbol_Object,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 6));
      Ignored := LM.Add_Symbol
        (First, "Alpha", LM.Symbol_Object,
         (Start_Line => 1, Start_Column => 4, End_Line => 1, End_Column => 8));
      Ignored := LM.Add_Symbol
        (Second, "Beta", LM.Symbol_Object,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 7));
      Ignored := LM.Add_Symbol
        (Second, "alpha", LM.Symbol_Object,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 8));

      LS.Put_Buffer_Analysis (Service, "/project/z.ads", 8, 1, 1, First);
      LS.Put_Buffer_Analysis (Service, "/project/a.ads", 9, 1, 1, Second);

      Items := LS.Complete (Service, "", 2);
      Assert (Items.Status = LS.Service_Success,
              "completion sorting still returns successful prefix matches");
      Assert (Natural (Items.Items.Length) = 2,
              "completion applies GUI limit after deterministic ordering");
      Assert (To_String (Items.Items (Items.Items.First_Index).Label) = "alpha",
              "completion order is label-sorted and duplicate labels keep the best target");
      Assert (To_String (Items.Items (Items.Items.First_Index).Target.Path) =
              "/project/a.ads",
              "completion duplicate labels prefer the deterministic earliest target");
      Assert (To_String (Items.Items (Items.Items.First_Index + 1).Label) = "Beta",
              "completion limit keeps the next sorted unique label");
   end Test_Service_Completions_Are_Deterministic_And_Limited;

   procedure Test_Service_References_And_Rename_Edits_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      First   : LM.Analysis_Result;
      Second  : LM.Analysis_Result;
      Refs    : LS.Language_Target_Set;
      Preview : LS.Rename_Preview;
      Ignored : LM.Symbol_Id;
   begin
      Ignored := LM.Add_Symbol
        (First, "Shared", LM.Symbol_Object,
         (Start_Line => 9, Start_Column => 4, End_Line => 9, End_Column => 9));
      Ignored := LM.Add_Symbol
        (Second, "Shared", LM.Symbol_Object,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 9));
      Ignored := LM.Add_Symbol
        (Second, "Shared", LM.Symbol_Object,
         (Start_Line => 1, Start_Column => 4, End_Line => 1, End_Column => 9));

      LS.Put_Buffer_Analysis (Service, "/project/z.ads", 10, 1, 1, First);
      LS.Put_Buffer_Analysis (Service, "/project/a.ads", 11, 1, 1, Second);

      Refs := LS.Find_References (Service, "Shared");
      Assert (Refs.Status = LS.Service_Success,
              "reference sorting preserves successful lookups");
      Assert (Natural (Refs.Targets.Length) = 3,
              "reference sorting preserves all retained targets");
      Assert (To_String (Refs.Targets (Refs.Targets.First_Index).Target.Path) =
              "/project/a.ads",
              "reference targets are sorted by path before insertion order");
      Assert (Refs.Targets (Refs.Targets.First_Index).Target.Line = 1,
              "reference targets are sorted by source position within a path");

      Preview := LS.Preview_Rename (Service, "Shared", "Renamed");
      Assert (Preview.Status = LS.Service_Success,
              "rename preview preserves deterministic successful result");
      Assert (Natural (Preview.Edits.Length) = 3,
              "rename preview keeps sorted edit targets");
      Assert (To_String (Preview.Edits (Preview.Edits.First_Index).Target.Path) =
              "/project/a.ads",
              "rename preview edit targets reuse deterministic reference order");
      Assert (Preview.Edits (Preview.Edits.First_Index).Target.Line = 1,
              "rename preview edit targets are source-position sorted");
   end Test_Service_References_And_Rename_Edits_Are_Deterministic;

   procedure Test_Service_Workspace_Symbols_Are_Deterministic_And_Bounded
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      First   : LM.Analysis_Result;
      Second  : LM.Analysis_Result;
      Many    : LM.Analysis_Result;
      Symbols : LS.Language_Target_Set;
      Ignored : LM.Symbol_Id;
   begin
      Ignored := LM.Add_Symbol
        (First, "Zoo_Action", LM.Symbol_Procedure,
         (Start_Line => 9, Start_Column => 4, End_Line => 9, End_Column => 13));
      Ignored := LM.Add_Symbol
        (First, "Alpha_Action", LM.Symbol_Procedure,
         (Start_Line => 4, Start_Column => 4, End_Line => 4, End_Column => 15));
      Ignored := LM.Add_Symbol
        (Second, "alpha_action", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 4, End_Line => 2, End_Column => 15));
      Ignored := LM.Add_Symbol
        (Second, "Middle_Action", LM.Symbol_Procedure,
         (Start_Line => 3, Start_Column => 4, End_Line => 3, End_Column => 16));

      LS.Put_Buffer_Analysis (Service, "/project/z.ads", 16, 1, 1, First);
      LS.Put_Buffer_Analysis (Service, "/project/a.ads", 17, 1, 1, Second);

      Symbols := LS.Workspace_Symbols (Service, "action");
      Assert (Symbols.Status = LS.Service_Success,
              "workspace symbols find normalized substring matches");
      Assert (Natural (Symbols.Targets.Length) = 4,
              "workspace symbols include all matching project declarations");
      Assert (To_String (Symbols.Targets (Symbols.Targets.First_Index).Name) =
              "alpha_action",
              "workspace symbols are sorted by normalized name first");
      Assert (To_String (Symbols.Targets (Symbols.Targets.First_Index).Target.Path) =
              "/project/a.ads",
              "workspace symbol ordering breaks name ties by source target");
      Assert (To_String (Symbols.Targets (Symbols.Targets.First_Index + 1).Name) =
              "Alpha_Action",
              "workspace symbol ordering preserves deterministic case ties");

      LS.Clear (Service);
      for I in 1 .. 201 loop
         Ignored := LM.Add_Symbol
           (Many, "Shared_Action", LM.Symbol_Procedure,
            (Start_Line => I, Start_Column => 4,
             End_Line => I, End_Column => 16));
      end loop;
      LS.Put_Buffer_Analysis (Service, "/project/many.ads", 18, 1, 1, Many);

      Symbols := LS.Workspace_Symbols (Service, "Shared");
      Assert (Symbols.Status = LS.Service_Overflow,
              "workspace symbols report service-side truncation");
      Assert (Symbols.Targets.Is_Empty,
              "overflowed workspace symbols do not expose partial targets");
   end Test_Service_Workspace_Symbols_Are_Deterministic_And_Bounded;

   procedure Test_Service_Navigation_Candidates_Are_Deterministic
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service : LS.Service_State;
      First   : LM.Analysis_Result;
      Second  : LM.Analysis_Result;
      Parent  : LM.Analysis_Result;
      Sep     : LM.Analysis_Result;
      Flags   : LM.Declaration_Flags := (others => False);
      Sep_Flags : LM.Declaration_Flags := (others => False);
      Bodies  : LS.Language_Target_Set;
      Specs   : LS.Language_Target_Set;
      Req     : LS.Semantic_Request_Id;
      Ignored : LM.Symbol_Id;
   begin
      Flags.Is_Body := True;
      Ignored := LM.Add_Symbol
        (First, "Run", LM.Symbol_Procedure,
         (Start_Line => 9, Start_Column => 14, End_Line => 9, End_Column => 16),
         Profile_Summary => "(Count : Natural)",
         Flags => Flags);
      Ignored := LM.Add_Symbol
        (Second, "Run", LM.Symbol_Procedure,
         (Start_Line => 2, Start_Column => 14, End_Line => 2, End_Column => 16),
         Profile_Summary => "(Count : Natural)",
         Flags => Flags);

      LS.Put_Buffer_Analysis (Service, "/project/z.adb", 12, 1, 1, First);
      LS.Put_Buffer_Analysis (Service, "/project/a.adb", 13, 1, 1, Second);

      Bodies := LS.Goto_Body
        (Service, "Run", LM.Symbol_Procedure, "(Count : Natural)");
      Assert (Bodies.Status = LS.Service_Ambiguous,
              "multiple body candidates remain explicit ambiguous navigation");
      Assert (Natural (Bodies.Targets.Length) = 2,
              "navigation candidate sorting preserves all body targets");
      Assert (To_String (Bodies.Targets (Bodies.Targets.First_Index).Target.Path) =
              "/project/a.adb",
              "navigation body candidates are sorted by path");
      Assert (Bodies.Targets (Bodies.Targets.First_Index).Target.Line = 2,
              "navigation body candidates preserve source position metadata");

      Ignored := LM.Add_Symbol
        (Parent, "Separate_Run", LM.Symbol_Procedure,
         (Start_Line => 4, Start_Column => 14, End_Line => 4, End_Column => 16));
      Sep_Flags.Is_Separate := True;
      Ignored := LM.Add_Symbol
        (Sep, "Separate_Run", LM.Symbol_Separate_Body,
         (Start_Line => 1, Start_Column => 18, End_Line => 1, End_Column => 20),
         Flags => Sep_Flags,
         Target_Name => "Separate_Run");
      LS.Put_Buffer_Analysis (Service, "/project/parent.ads", 14, 1, 1, Parent);
      LS.Put_Buffer_Analysis (Service, "/project/run.adb", 15, 1, 1, Sep);

      Specs := LS.Goto_Spec
        (Service, "Separate_Run", LM.Symbol_Separate_Body);
      Assert (Specs.Status = LS.Service_Success
              and then Natural (Specs.Targets.Length) = 1,
              "separate body goto spec resolves its parent declaration");
      Assert (To_String (Specs.Targets (Specs.Targets.First_Index).Target.Path) =
              "/project/parent.ads",
              "separate body goto spec targets the parent unit path");

      Req := LS.Begin_Semantic_Request
        (Service, LS.Semantic_Request_Goto_Spec,
         LS.Semantic_Request_Query_Key
           (LS.Semantic_Request_Goto_Spec, "Separate_Run", "",
            Detail => LM.Symbol_Kind'Image (LM.Symbol_Separate_Body)));
      Specs := LS.Request_Goto_Spec
        (Service, Req, "Separate_Run", LM.Symbol_Separate_Body);
      Assert (Specs.Status = LS.Service_Success
              and then LS.Active_Semantic_Request (Service).Kind =
                LS.Semantic_Request_Goto_Spec
              and then LS.Active_Semantic_Request (Service).Status =
                LS.Semantic_Request_Completed,
              "separate body request goto spec records completed request");
   end Test_Service_Navigation_Candidates_Are_Deterministic;

   procedure Test_Service_References_Are_Bounded_For_GUI_Use
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Service  : LS.Service_State;
      Analysis : LM.Analysis_Result;
      Refs     : LS.Language_Target_Set;
      Preview  : LS.Rename_Preview;
      Ignored  : LM.Symbol_Id;
   begin
      for I in 1 .. 201 loop
         Ignored := LM.Add_Symbol
           (Analysis, "Shared", LM.Symbol_Object,
            (Start_Line => I, Start_Column => 4,
             End_Line => I, End_Column => 9));
      end loop;

      Assert (not LM.Overflowed (Analysis),
              "test analysis must exercise service cap, not model overflow");

      LS.Put_Buffer_Analysis
        (Service, "/project/repeated.ads", 5, 1, 1, Analysis);

      Refs := LS.Find_References (Service, "Shared");
      Assert (Refs.Status = LS.Service_Overflow,
              "reference lookup must report service-side truncation");
      Assert (Refs.Targets.Is_Empty,
              "overflowed reference lookup should not expose partial targets");

      Preview := LS.Preview_Rename (Service, "Shared", "Renamed");
      Assert (Preview.Status = LS.Service_Overflow,
              "rename preview must not execute on a truncated reference set");
      Assert (Preview.Edit_Count = 0,
              "overflowed rename preview must not expose partial edit counts");
   end Test_Service_References_Are_Bounded_For_GUI_Use;

   procedure Test_Service_Cap_Boundaries_Are_Not_Overflow
     (T : in out AUnit.Test_Cases.Test_Case'Class)
   is
      pragma Unreferenced (T);
      Hover_Service : LS.Service_State;
      Hover_Analysis : LM.Analysis_Result;
      Ref_Service : LS.Service_State;
      Ref_Analysis : LM.Analysis_Result;
      Hover : LS.Hover_Result;
      Refs  : LS.Language_Target_Set;
      Ignored : LM.Symbol_Id;
   begin
      for I in 1 .. 2 loop
         Ignored := LM.Add_Symbol
           (Hover_Analysis, "Twin", LM.Symbol_Object,
            (Start_Line => I, Start_Column => 4,
             End_Line => I, End_Column => 7));
      end loop;
      LS.Put_Buffer_Analysis
        (Hover_Service, "/project/twins.ads", 6, 1, 1, Hover_Analysis);

      Hover := LS.Hover (Hover_Service, "Twin");
      Assert (Hover.Status = LS.Service_Ambiguous,
              "exactly two hover candidates are ambiguous, not overflowed");

      for I in 1 .. 200 loop
         Ignored := LM.Add_Symbol
           (Ref_Analysis, "Boundary", LM.Symbol_Object,
            (Start_Line => I, Start_Column => 4,
             End_Line => I, End_Column => 11));
      end loop;
      LS.Put_Buffer_Analysis
        (Ref_Service, "/project/boundary.ads", 7, 1, 1, Ref_Analysis);

      Refs := LS.Find_References (Ref_Service, "Boundary");
      Assert (Refs.Status = LS.Service_Success,
              "exactly capped references should remain a complete result");
      Assert (Natural (Refs.Targets.Length) = 200,
              "reference cap boundary preserves all retained targets");
   end Test_Service_Cap_Boundaries_Are_Not_Overflow;

   overriding procedure Register_Tests (T : in out Test_Case) is
      use AUnit.Test_Cases.Registration;
   begin
      Register_Routine
        (T, Test_Service_Navigation_Completion_And_Hover'Access,
         "Ada language service exposes navigation completion and hover");
      Register_Routine
        (T, Test_Service_Semantic_Request_Lifecycle_Guards_Results'Access,
         "Ada language service semantic requests guard result lifecycles");
      Register_Routine
        (T, Test_Service_Rename_And_Snapshot_Invalidation'Access,
         "Ada language service previews rename conflicts and invalidates snapshots");
      Register_Routine
        (T, Test_Service_Compiler_Backend_Consumes_GNAT_Diagnostics'Access,
         "Ada language service consumes compiler backend diagnostics");
      Register_Routine
        (T, Test_Service_Compiler_Backend_Bounds_Diagnostics'Access,
         "Ada language service bounds compiler backend diagnostics");
      Register_Routine
        (T, Test_Service_Reindex_Preserves_Compiler_Backend'Access,
         "Ada language service reindex preserves compiler backend diagnostics");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Publish_To_Backend'Access,
         "Ada language service consumes live semantic diagnostics");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Include_Expressions'Access,
         "Ada language service live semantic diagnostics include expressions");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Retain_Multiple_Files'Access,
         "Ada language service live semantic diagnostics retain multiple files");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Include_Generics'Access,
         "Ada language service live semantic diagnostics include generics");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Include_Stream_Profiles'Access,
         "Ada language service live semantic diagnostics include stream profiles");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Include_Return_Mismatches'Access,
         "Ada language service live semantic diagnostics include return type mismatches");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Include_Assignment_Mismatches'Access,
         "Ada language service live semantic diagnostics include assignment type mismatches");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Use_Project_Cross_Unit_Lookup'Access,
         "Ada language service live semantic diagnostics use project cross-unit lookup");
      Register_Routine
        (T, Test_Service_Live_Semantic_Diagnostics_Include_Cross_Units'Access,
         "Ada language service live semantic diagnostics include cross units");
      Register_Routine
        (T, Test_Service_Internal_Semantic_Diagnostics_Are_Visible'Access,
         "Ada language service exposes internal semantic diagnostics");
      Register_Routine
        (T, Test_Service_Internal_Semantic_Diagnostics_Are_Bounded'Access,
         "Ada language service bounds internal semantic diagnostics");
      Register_Routine
        (T, Test_Service_Consumes_Guarded_Semantic_Diagnostic_Feed'Access,
         "Ada language service consumes guarded semantic diagnostic feed");
      Register_Routine
        (T, Test_Service_Rename_Rejects_Invalid_New_Names'Access,
         "Ada language service rejects invalid rename targets");
      Register_Routine
        (T, Test_Service_Current_References_Report_Stale_Snapshots'Access,
         "Ada language service current references report stale snapshots");
      Register_Routine
        (T, Test_Service_Completion_Reports_Overflowed_Index'Access,
         "Ada language service completion reports overflowed indexes");
      Register_Routine
        (T, Test_Service_Completions_Are_Deterministic_And_Limited'Access,
         "Ada language service completions are deterministic and limited");
      Register_Routine
        (T, Test_Service_References_And_Rename_Edits_Are_Deterministic'Access,
         "Ada language service references and rename edits are deterministic");
      Register_Routine
        (T, Test_Service_Workspace_Symbols_Are_Deterministic_And_Bounded'Access,
         "Ada language service workspace symbols are deterministic and bounded");
      Register_Routine
        (T, Test_Service_Navigation_Candidates_Are_Deterministic'Access,
         "Ada language service navigation candidates are deterministic");
      Register_Routine
        (T, Test_Service_References_Are_Bounded_For_GUI_Use'Access,
         "Ada language service bounds GUI reference lookups");
      Register_Routine
        (T, Test_Service_Cap_Boundaries_Are_Not_Overflow'Access,
         "Ada language service cap boundaries are not overflow");
   end Register_Tests;

end Test_Ada_Language_Service_Integration;
