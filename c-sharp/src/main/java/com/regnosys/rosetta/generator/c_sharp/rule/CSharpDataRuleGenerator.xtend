package com.regnosys.rosetta.generator.c_sharp.rule

import com.google.common.base.CaseFormat
import com.google.inject.Inject
import com.regnosys.rosetta.RosettaExtensions
import java.util.List

import com.regnosys.rosetta.generator.c_sharp.expression.ExpressionGenerator
import com.regnosys.rosetta.generator.c_sharp.expression.ExpressionGenerator.ParamMap
import com.regnosys.rosetta.generator.java.function.RosettaFunctionDependencyProvider
//import com.regnosys.rosetta.generator.java.util.ImportManagerExtension
//import com.regnosys.rosetta.generator.java.util.JavaNames
import com.regnosys.rosetta.generator.java.util.RosettaGrammarUtil
import com.regnosys.rosetta.rosetta.RosettaConditionalExpression
import com.regnosys.rosetta.rosetta.RosettaType

import com.regnosys.rosetta.rosetta.simple.Condition
import com.regnosys.rosetta.rosetta.simple.Data

//import com.rosetta.model.lib.RosettaModelObjectBuilder
//import com.rosetta.model.lib.annotations.RosettaDataRule
//import com.rosetta.model.lib.path.RosettaPath
//import com.rosetta.model.lib.validation.ComparisonResult
import com.rosetta.model.lib.validation.ModelObjectValidator
//import com.rosetta.model.lib.validation.ValidationResult
//import com.rosetta.model.lib.validation.ValidationResult.ValidationType
//import com.rosetta.model.lib.validation.Validator

import org.eclipse.xtend2.lib.StringConcatenationClient
/*
import org.eclipse.xtext.generator.IFileSystemAccess2
*/
import static com.regnosys.rosetta.generator.c_sharp.util.CSharpModelGeneratorUtil.*
//import static com.regnosys.rosetta.generator.java.util.ModelGeneratorUtil.*
import static com.regnosys.rosetta.rosetta.simple.SimplePackage.Literals.CONDITION__EXPRESSION

class CSharpDataRuleGenerator {
    @Inject ExpressionGenerator expressionHandler
    @Inject extension RosettaExtensions
    //@Inject extension ImportManagerExtension
    @Inject RosettaFunctionDependencyProvider funcDependencies
    
    /*
    def generate(JavaNames names, IFileSystemAccess2 fsa, Data data, Condition ele, String version) {
        val classBody = tracImports(ele.dataRuleClassBody(data, names, version))
        val content = '''
            package «names.packages.model.dataRule.name»;
            
            «FOR imp : classBody.imports»
                import «imp»;
            «ENDFOR»
            «»
            «FOR imp : classBody.staticImports»
                import static «imp»;
            «ENDFOR»
            
            «classBody.toString»
        '''
        fsa.generateFile('''«names.packages.model.dataRule.directoryName»/«dataRuleClassName(ele, data)».java''', content)
    }
    */

    def generateDataRules(List<Data> rosettaClasses, String version) {
        '''
        «fileComment(version)»
        namespace Org.Isda.Cdm.Validation.DataRule
        {
            using System;
            using System.Linq;
            
            using Org.Isda.Cdm;
            
            using Rosetta.Lib.Attributes;
            using Rosetta.Lib.Functions;
            using Rosetta.Lib.Validation;
            
        «FOR rosettaClass : rosettaClasses»
            «FOR c : rosettaClass.conditions»
                «IF !c.isChoiceRuleCondition»«c.dataRuleClassBody(rosettaClass, version)»«ENDIF»
            «ENDFOR»
        «ENDFOR»
        }
        '''
    }

    def static String dataRuleClassName(String dataRuleName) {
        val allUnderscore = CaseFormat.UPPER_CAMEL.to(CaseFormat.LOWER_UNDERSCORE, dataRuleName)
        val camel = CaseFormat.LOWER_UNDERSCORE.to(CaseFormat.UPPER_CAMEL, allUnderscore)
        return camel
    }
    
    def  String dataRuleClassName(Condition cond, Data data) {
        dataRuleClassName(cond.conditionName(data))
    }
    
    private def StringConcatenationClient dataRuleClassBody(Condition rule, Data data /*, JavaNames javaName*/, String version)  {
        val rosettaClass = rule.eContainer as RosettaType
        val expression = rule.expression
        
        val ruleWhen = if(expression instanceof RosettaConditionalExpression ) expression.^if
        val ruleThen = if(expression instanceof RosettaConditionalExpression ) expression.ifthen else expression
        
        val definition = RosettaGrammarUtil.quote(RosettaGrammarUtil.extractNodeText(rule, CONDITION__EXPRESSION))
        val ruleName = rule.conditionName(data)
        //val funcDeps = funcDependencies.functionDependencies(#[ruleWhen , ruleThen])
        '''
        «""»
            «comment(rule.definition)»
            [RosettaDataRule("«ruleName»")]
            public class «dataRuleClassName(ruleName)» : AbstractDataRule<«rosettaClass.name»>
            {
                protected override string Definition => «definition»;
««« TODO: Work out dependencies????
«««                «FOR dep : funcDeps»
«««                    @«Inject» protected «javaName.toJavaType(dep)» «dep.name.toFirstLower»;
«««                «ENDFOR»
                
                protected override IComparisonResult RuleIsApplicable(«rosettaClass.name» «rosettaClass.name.toFirstLower»)
                {
                    «IF ruleWhen === null»
                        return ComparisonResult.Success();
                    «ELSE»
                    try
                    {
                        return ComparisonResult.FromBoolean(«expressionHandler.csharpCode(ruleWhen, new ParamMap(rosettaClass))»);
                    }
                    catch (Exception ex)
                    {
                        return ComparisonResult.Failure(ex.Message);
                    }
                    «ENDIF»
                }
                
                protected override IComparisonResult EvaluateThenExpression(«rosettaClass.name» «rosettaClass.name.toFirstLower»)
                {
                    try
                    {
                        return ComparisonResult.FromBoolean(«expressionHandler.csharpCode(ruleThen, new ParamMap(rosettaClass))»);
                    }
                    catch (Exception ex)
                    {
                        return ComparisonResult.Failure(ex.Message);
                    }
                }
            }
        
        '''
    }
}

