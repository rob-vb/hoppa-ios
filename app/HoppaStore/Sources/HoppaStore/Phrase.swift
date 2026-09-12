/// Closed chrome catalog. Interpolation and domain values are methods on `Phrasebook`.
/// A new screen string is a new case. Missing Dutch does not compile.
public enum Phrase: Sendable, Hashable {
    case tabHome, tabHistory, tabProgress, tabSettings
    case language, selected

    case nothingHereYet, createAProgram, pickADay, running
    case hoppaCannotReadLogbook, fileUnchanged
    case resume, finishIt, discardIt, discardThisWorkout
    case everyLoggedSetGoes, keepIt

    case workoutDays, addADay, startAWorkout, programSettings
    case unitProgressionPlateRack, thatProgramIsGone, back
    case name, weightUnit, progression, plateRack, done, cancel, save
    case renameTheProgram, saveTheName
    case renamingChangesNothing
    case progressionMode, weightUnitDefaultNote
    case nameTheDay, addTheDay, dayNameHint
    case giveItANameFirst
    case aProgramNeedsOneDay
    case standardRack, customRack

    case equipmentType, newExercise, saveExercise, removeExercise
    case progressionForThisExercise, discardThisExercise, keepEditing
    case nothingSavedUntilSave, removeThisExercise
    case leavesProgramFromToday
    case baseWeightMachine, stackStep, firstPlate
    case sets, repRange, totalWorkingWeight, increment
    case microloadingIncrement, noMicroplatesSetUpRack
    case baseWeightAppears, changesSaveOnClose
    case nameYourProgram, continueLabel
    case yourPlateRack, thisIsMyRack
    case platesYouOwn, microplates, stackAddOns
    case switchItOff, microplatesNeed, noPlateSwitchedOn
    case withMicroloading, nothingOn
    case thisUnitApplies

    case history, progress, summary, reweigh, weight
    case weekInARow, weeksInARow
    case finishFirstWorkoutLandsHere
    case finishWorkoutLandsExercisesHere
    case thatExerciseIsGone, oneSessionIsADot
    case thisExerciseGetsALine
    case wentUp, stayed, oneOff, skipped
    case lastSessions, timesUp, pinUnchanged, onThePin, sinceThen
    case workingWeight, pin, microloadOnThePin
    case nothingWentUp, exerciseWentUp, exercisesWentUp
    case hoppaAlreadyChangedTheWeight
    case noExercisesPerformed
    case nextTime, duration, volumeSuffix
    case removedFromTheProgram
    case thatWorkoutIsGone
    case everyExerciseHasAWeight
    case reweighIntro
    case noBaseWeight, noIncrement, noMicroplate

    case finishWorkout, discardTheWorkout, changeTheWeight
    case skipThisExercise, doneEarly, putItBack
    case notAtAll, reopen, notSetYet, notDone
    case resting, ready, noWeightYetTap
    case setTheWeight, justToday, fromNowOn
    case justTodayOrFromNowOn
    case thatDayIsGone
    case hoppaCouldNotRead, nothingChangedOnPhone
    case removedFromProgramKept
    case dayDone, removeDay, rename, addAnExercise, noExercisesYet
    case renameTheDay, removeThisDay
    case chartPin, chartWorkingWeight
    case mixedUnitNothingConverts
    case setAtLabel

    case perSide, closest
    case useNameAsTyped

    case discard
    case youCanRenameItLater
    case whatHoppaAlreadyPicked
    case hoppaPickedTheseThree
    case keepLogging
    case skipAndFinish
    case finishTheWorkout
    case deleteThisWorkout
    case deleteWorkout
    case workingWeightsStay
    case eachHand
    case addedWeightOnly
    case noPlates
    case noSetsYet
    case leavingOpenExercise
    case hoppaKeepsOneWorkout
    case close
    case reps
    case tapARowToOpenIt
    case dayLeavesKeepName
    case everyExerciseEndsCompleted
    case oneOffNeverWritten
    case becomesWorkingWeight
    case skipIt
    case skipThem
    case notBuiltYet

    case remove
    case delete
    case stranded
    case micro
    case completed
    case openLabel
    case now
    case next
    case onTheBelt
    case over
    case under
    case unitSwitchClears
    case stateOpen
    case stateCompleted
    case willNotProgress
    case ticket
    case plateNoun
}
