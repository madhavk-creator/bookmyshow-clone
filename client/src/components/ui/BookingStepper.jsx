import { Check } from 'lucide-react'

const STEPS = [
  { id: 1, label: 'Select Show' },
  { id: 2, label: 'Choose Seats' },
  { id: 3, label: 'Payment' },
]

export function BookingStepper({ currentStep }) {
  return (
    <div className="sticky top-16 w-full py-4 px-2 sm:px-4 border-b border-neutral-200 dark:border-neutral-800 bg-white/80 dark:bg-[rgba(11,9,15,0.85)] backdrop-blur-lg z-40 shadow-sm">
      <div className="max-w-4xl mx-auto flex items-center justify-between">
        {STEPS.map((step, index) => {
          const isCompleted = currentStep > step.id
          const isCurrent = currentStep === step.id
          
          return (
            <div key={step.id} className="flex items-center flex-1 last:flex-none">
              <div className="flex flex-col sm:flex-row items-center gap-2 sm:gap-3">
                <div 
                  className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold transition-all
                    ${isCompleted 
                      ? 'bg-primary-500 text-white shadow-md shadow-primary-500/30' 
                      : isCurrent 
                        ? 'border-2 border-primary-500 text-primary-600 dark:text-primary-400 bg-primary-500/10 shadow-sm'
                        : 'border-2 border-neutral-300 dark:border-neutral-700 text-neutral-400 dark:text-neutral-500 bg-neutral-100 dark:bg-neutral-800/50'
                    }
                  `}
                >
                  {isCompleted ? <Check className="w-5 h-5" /> : step.id}
                </div>
                <span 
                  className={`text-[10px] sm:text-xs font-bold uppercase tracking-[0.15em] text-center sm:text-left
                    ${isCurrent || isCompleted 
                      ? 'text-neutral-900 dark:text-white' 
                      : 'text-neutral-400 dark:text-neutral-500'
                    }
                  `}
                >
                  {step.label}
                </span>
              </div>
              
              {/* Connector line */}
              {index < STEPS.length - 1 && (
                <div className={`flex-1 border-t-2 mx-4 sm:mx-6 transition-colors hidden sm:block ${isCompleted ? 'border-primary-500 opacity-50' : 'border-neutral-200 dark:border-neutral-800'}`} />
              )}
            </div>
          )
        })}
      </div>
    </div>
  )
}
